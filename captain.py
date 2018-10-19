import logging
import os
import paramiko
import signal
import socket
import sys
import time
import urllib.parse
import urllib.request

PROBE_TIME_OUT_SECONDS = 10
SSH_USERNAME = "core"
TCP_PORT = 15621

class CaptainException(Exception):
    pass


def setup_logger():
    logger = logging.getLogger("TDSLogger")
    logger.setLevel(logging.INFO)
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    formatter = logging.Formatter("%(asctime)s - %(levelname)s - %(message)s")
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    return logger


def start():
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)

    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.bind(("", TCP_PORT))
    server.listen(1)

    logger.info("Listening for client...")

    while True:
        client, addr = server.accept()
        logger.info("Connection from: %s", repr(addr))
        request = client.recv(4096)
        response = handle_request(request)
        response_message = "HTTP/1.1 " + response['status'] + "\nContent-Type: application/json\n\n{\"status\": \"" + response['status'] + "\", \"message\": \"" + response['message'] + "\"}\n"
        client.send(response_message.encode("UTF-8"))
        client.close()


def signal_handler(sig, frame):
    sys.exit(0)


def handle_request(request):
    decoded_request = request.decode("UTF-8")
    url_part = decoded_request.split(" ")[1]
    url = urllib.parse.urlparse(url_part)
    path = url.path
    query = urllib.parse.parse_qs(url.query)
    if(path == "/update/"):
        response = handle_update(query)
    else:
        response = {
            "message": "Don't know how to handle request: " + url_part,
            "status": "500"
        }

    return response


def handle_update(options):
    response = {
        "message": "OK",
        "status": "200"
    }

    try:
        if(options_correct(options)):
            app = options["app"][0]
            docker_image_name = options["docker_image_name"][0]
            docker_image_tag = options["docker_image_tag"][0]
            probe_path = options.get("probe_path", [""])[0]
            app_environment = options["env"][0].upper()
            app_servers_var = "APP_SERVERS_" + app_environment
            servers = os.environ[app_servers_var].split(" ")
            servers_to_update = []

            logger.info("Asking to update:")
            logger.info("- environment: %s", app_environment)
            logger.info("- servers: %s", servers)
            logger.info("- app: %s", app)
            logger.info("- docker_image_name: %s", docker_image_name)
            logger.info("- docker_image_tag: %s", docker_image_tag)
            logger.info("- probe_path: %s", probe_path)

            for server in servers:
                client = paramiko.client.SSHClient()
                client.load_system_host_keys()
                client.set_missing_host_key_policy(paramiko.client.AutoAddPolicy)
                client.connect(server, "22", SSH_USERNAME)

                service_present = app_service_present(client, app)

                if(service_present):
                    logger.info("app present on %s", server)
                    servers_to_update.append(server)
                else:
                    logger.info("app not present on %s", server)

                client.close()

            for server in servers_to_update:
                client = paramiko.client.SSHClient()
                client.load_system_host_keys()
                client.set_missing_host_key_policy(paramiko.client.AutoAddPolicy)
                client.connect(server, "22", SSH_USERNAME)

                logger.info("updating %s:%s on %s", docker_image_name, docker_image_tag, server)
                update_docker_image_response = update_docker_image(client, docker_image_name, docker_image_tag)

                if(update_docker_image_response != 0):
                    logger.warn("Updating of the docker image on %s failed, the deploy process was stopped.", server)
                    client.close()
                    raise CaptainException("Updating of the docker image on " + server + " failed, the deploy process was stopped.")

                client.close()

            for server in servers_to_update:
                client = paramiko.client.SSHClient()
                client.load_system_host_keys()
                client.set_missing_host_key_policy(paramiko.client.AutoAddPolicy)
                client.connect(server, "22", SSH_USERNAME)

                logger.info("restarting %s on %s", app, server)
                restart_service_response = restart_service(client, app)

                if(probe_path != ""):
                    logger.info("probing %s", probe_path)
                    logger.info("waiting at most %s for %s to come back on %s...", PROBE_TIME_OUT_SECONDS, app, server)
                    probe_success = probe_service(client, app, probe_path)

                    if not(probe_success):
                        logger.warn("It seems that %s on %s did not come back up, the deploy process was stopped.", app, server)
                        client.close()
                        raise CaptainException("It seems that " + app + " on " + server + " did not come back up, the deploy process was stopped.")

                if(restart_service_response != 0):
                    logger.warn("Restarting %s on %s failed, the deploy process was stopped.", app, server)
                    client.close()
                    raise CaptainException("Restarting " + app + " on " + server + " failed, the deploy process was stopped.")

                client.close()

            logger.info("%s was deployed on all servers", app)
        else:
            logger.warn("Options are not correct", options)
            response = {
                "message": "missing options",
                "status": "400"
            }

    except Exception as e:
        response = {
            "message": format(e),
            "status": "400"
        }
    finally:
        return response


def options_correct(options):
    try:
        options["app"]
        options["env"]
        options["docker_image_name"]
        options["docker_image_tag"]
        return True
    except KeyError:
        return False


def app_service_present(client, app):
    stdin, stdout, stderr = client.exec_command("systemctl list-units | grep " + app)
    result = stdout.read().decode()

    return result != ""


def update_docker_image(client, docker_image_name, docker_image_tag):
    docker_image = os.environ["DOCKER_REGISTRY_HOST"] + ":" + os.environ["DOCKER_REGISTRY_PORT"] + "/thedutchselection/" + docker_image_name + ":" + docker_image_tag
    stdin, stdout, stderr = client.exec_command("docker pull " + docker_image)

    return stdout.channel.recv_exit_status()


def restart_service(client, app):
    stdin, stdout, stderr = client.exec_command("sudo systemctl restart " + app)

    return stdout.channel.recv_exit_status()


def probe_service(client, app, probe_path):
    stdin, stdout, stderr = client.exec_command("docker inspect --format '{{ .NetworkSettings.Gateway }}' " + app)
    docker_gateway = stdout.read().decode().rstrip()
    stdin, stdout, stderr = client.exec_command("docker port " + app)
    docker_port_result = stdout.read().decode().rstrip()
    docker_port = docker_port_result[docker_port_result.index(':') + 1:docker_port_result.index(':') + 5]
    url = "http://" + docker_gateway + ":" + docker_port + probe_path
    timeout = time.time() + PROBE_TIME_OUT_SECONDS
    probe_result = False

    while True:
        time.sleep(1)

        if(time.time() > timeout):
            probe_result = False
            break

        stdin, stdout, stderr = client.exec_command("curl -s -o /dev/null -w \"%{http_code}\" " + url)
        status = stdout.read().decode()

        if(status == "200"):
            probe_result = True
            break

    return probe_result


logger = setup_logger()
start()

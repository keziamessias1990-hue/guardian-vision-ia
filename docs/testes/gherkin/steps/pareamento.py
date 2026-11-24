import json
import os
from urllib.error import HTTPError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
from uuid import uuid4

from behave import given, then, when


def post(context, path, payload, token=None):
    headers = {"Content-Type": "application/json"}
    if token:
        headers["Authorization"] = f"Bearer {token}"
    request = Request(
        context.api_url + path,
        data=json.dumps(payload).encode(),
        headers=headers,
        method="POST",
    )
    try:
        with urlopen(request, timeout=8) as response:
            return response.status, json.load(response)
    except HTTPError as error:
        with error:
            return error.code, None


@given("que o responsável gerou um código de pareamento para seu perfil infantil")
def create_pairing(context):
    context.api_url = os.environ["GUARDIAN_TEST_URL"].rstrip("/")
    url = urlsplit(context.api_url)
    assert url.scheme == "http" and url.hostname in ("127.0.0.1", "localhost")
    assert url.path == "/api", "Use a URL da instância Guardian de teste."
    credentials = {
        "email": f"behave-{uuid4().hex}@guardian.test",
        "password": "GuardianBehave2026",
    }
    assert post(context, "/auth/register", credentials)[0] == 201
    status, session = post(context, "/auth/login", credentials)
    assert status == 201
    token = session["accessToken"]
    context.add_cleanup(post, context, "/auth/logout", {}, token)
    status, child = post(context, "/children", {"name": "Perfil fictício Behave", "ageGroup": "11-13"}, token)
    assert status == 201
    status, pairing = post(context, f"/children/{child['id']}/pairings", {}, token)
    assert status == 201
    context.pairing_code = pairing["pairingCode"]


@when("o código é informado no Kids em minúsculas e com espaço no lugar do hífen")
def confirm_pairing(context):
    typed_code = context.pairing_code.lower().replace("-", " ")
    context.confirmation = post(context, "/pairings/confirm", {"pairingCode": typed_code})


@then("a API confirma o pareamento")
def check_link(context):
    status, result = context.confirmation
    assert status == 201
    assert result["childId"] and result["deviceToken"]


@then("uma nova tentativa com o mesmo código recebe HTTP 401")
def check_replay(context):
    status, _ = post(context, "/pairings/confirm", {"pairingCode": context.pairing_code})
    assert status == 401

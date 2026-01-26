DEBUG = True


def log_debug(msg: str):
    if DEBUG:
        print(msg)


def get_default_resultset() -> dict:
    return {
        "error": False,
        "error_message": "",
        "text": ""
    }

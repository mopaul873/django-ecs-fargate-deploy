from .views import health


class HealthCheckMiddleware:
    """
    Answer /health/ before Django checks ALLOWED_HOSTS.

    The ALB health checker calls the task by its private IP, so the Host header
    is something like 10.0.11.23:8000. That IP is not in ALLOWED_HOSTS, which
    would make Django return 400 and the ALB would mark every task unhealthy.
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.path == "/health/":
            return health(request)
        return self.get_response(request)

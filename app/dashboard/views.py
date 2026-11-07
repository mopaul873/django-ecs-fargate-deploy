from django.conf import settings
from django.db import connection
from django.db.models import Avg, Sum
from django.http import JsonResponse
from django.shortcuts import render

from .models import Client, MediaMetric


def dashboard(request):
    """Main dashboard: totals per client."""
    summary = (
        MediaMetric.objects.values("client__name")
        .annotate(total_views=Sum("views"), avg_engagement=Avg("engagement_rate"))
        .order_by("-total_views")
    )
    context = {
        "summary": summary,
        "client_count": Client.objects.count(),
        "version": settings.APP_VERSION,
    }
    return render(request, "dashboard/index.html", context)


def health(request):
    """
    Health check used by the ALB target group and the container HEALTHCHECK.
    Returns 200 only if the app can reach the database.
    """
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
        db_ok = True
    except Exception:
        db_ok = False

    status = 200 if db_ok else 503
    return JsonResponse(
        {"status": "ok" if db_ok else "db_unavailable", "version": settings.APP_VERSION},
        status=status,
    )

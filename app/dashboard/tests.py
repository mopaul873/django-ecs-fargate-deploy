import datetime

from django.test import TestCase
from django.urls import reverse

from .models import Client, MediaMetric


class HealthCheckTests(TestCase):
    def test_health_returns_ok(self):
        response = self.client.get(reverse("health"))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.json()["status"], "ok")

    def test_health_works_with_unknown_host(self):
        # The ALB health check uses the task's private IP as the Host header
        response = self.client.get("/health/", HTTP_HOST="10.0.11.23:8000")
        self.assertEqual(response.status_code, 200)

    def test_other_pages_still_reject_unknown_host(self):
        response = self.client.get("/", HTTP_HOST="evil.example.com")
        self.assertEqual(response.status_code, 400)


class DashboardTests(TestCase):
    def test_empty_dashboard_loads(self):
        response = self.client.get(reverse("dashboard"))
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, "No metrics yet")

    def test_dashboard_shows_client_totals(self):
        acme = Client.objects.create(name="Acme Media")
        MediaMetric.objects.create(
            client=acme, channel="YouTube", date=datetime.date(2026, 11, 1),
            views=1000, engagement_rate=4.5,
        )
        MediaMetric.objects.create(
            client=acme, channel="TikTok", date=datetime.date(2026, 11, 1),
            views=500, engagement_rate=6.5,
        )
        response = self.client.get(reverse("dashboard"))
        self.assertContains(response, "Acme Media")
        self.assertContains(response, "1500")
        self.assertContains(response, "5.50")

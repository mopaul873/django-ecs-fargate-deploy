from django.contrib import admin

from .models import Client, MediaMetric


@admin.register(Client)
class ClientAdmin(admin.ModelAdmin):
    list_display = ("name", "created_at")


@admin.register(MediaMetric)
class MediaMetricAdmin(admin.ModelAdmin):
    list_display = ("client", "channel", "date", "views", "engagement_rate")
    list_filter = ("channel", "client")

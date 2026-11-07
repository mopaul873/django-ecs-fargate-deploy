from django.db import models


class Client(models.Model):
    """A paying client of the analytics platform."""

    name = models.CharField(max_length=100, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.name


class MediaMetric(models.Model):
    """One daily metric row (views, engagement) for a client's media channel."""

    client = models.ForeignKey(Client, on_delete=models.CASCADE, related_name="metrics")
    channel = models.CharField(max_length=50)  # e.g. YouTube, TikTok, Website
    date = models.DateField()
    views = models.PositiveIntegerField(default=0)
    engagement_rate = models.DecimalField(max_digits=5, decimal_places=2, default=0)

    class Meta:
        ordering = ["-date"]
        unique_together = ("client", "channel", "date")

    def __str__(self):
        return f"{self.client} - {self.channel} - {self.date}"

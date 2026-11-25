"""MQTT subscriber that feeds vehicle GPS fixes into the database.

Topic contract:   vehicles/<VEHICLE_CODE>/gps
Payload (JSON):   {"latitude": .., "longitude": .., "speed": .., "timestamp": ..}
                  (`vehicle_id` is optional; if present it must match the topic,
                  so one vehicle can never write data for another.)
"""
import json
import logging

import paho.mqtt.client as mqtt
from pydantic import ValidationError

from app.core.config import Settings
from app.db.session import SessionLocal
from app.schemas.gps import GpsIngest
from app.services.gps_service import InvalidFixError, UnknownVehicleError, ingest_point

log = logging.getLogger("gps.mqtt")


def process_message(topic: str, payload: bytes, session_factory=SessionLocal) -> bool:
    """Validate + store one message. Never raises (a bad message must not kill the loop)."""
    parts = topic.split("/")
    if len(parts) != 3 or parts[0] != "vehicles" or parts[2] != "gps":
        log.warning("Ignoring message on unexpected topic %s", topic)
        return False
    topic_code = parts[1]

    try:
        data = json.loads(payload)
        if not isinstance(data, dict):
            raise ValueError("payload must be a JSON object")
        data.setdefault("vehicle_id", topic_code)
        point = GpsIngest.model_validate(data)
    except ValueError as exc:  # JSONDecodeError and pydantic ValidationError both subclass it
        log.warning("Dropping invalid payload on %s: %s", topic, exc)
        return False

    if point.vehicle_id != topic_code:
        log.warning("Dropping %s: payload vehicle_id %s != topic", topic, point.vehicle_id)
        return False

    try:
        with session_factory() as db:
            stored = ingest_point(db, point)
        log.debug("GPS %s %s", topic, "stored" if stored else "duplicate")
        return stored
    except (UnknownVehicleError, InvalidFixError) as exc:
        log.warning("Rejected fix from %s: %r", topic, exc)
    except Exception:  # noqa: BLE001 - keep the subscriber alive
        log.exception("Failed to store GPS fix from %s", topic)
    return False


class MqttIngestor:
    def __init__(self, settings: Settings):
        self._s = settings
        self._client = mqtt.Client(
            mqtt.CallbackAPIVersion.VERSION2, client_id="gps-api-ingestor"
        )
        if settings.mqtt_username:
            self._client.username_pw_set(settings.mqtt_username, settings.mqtt_password)
        self._client.on_connect = self._on_connect
        self._client.on_message = self._on_message
        self._client.reconnect_delay_set(min_delay=1, max_delay=30)

    def _on_connect(self, client, userdata, flags, reason_code, properties=None):
        if reason_code == 0:
            # Subscribing here (not once at startup) re-subscribes after reconnects.
            client.subscribe(self._s.mqtt_topic, qos=1)
            log.info("MQTT connected, subscribed to %s", self._s.mqtt_topic)
        else:
            log.error("MQTT connect failed: %s", reason_code)

    def _on_message(self, client, userdata, msg):
        process_message(msg.topic, msg.payload)

    def start(self) -> None:
        # connect_async + loop_start: the API boots even if the broker is still
        # starting, and paho keeps retrying in its own thread.
        self._client.connect_async(self._s.mqtt_host, self._s.mqtt_port, keepalive=30)
        self._client.loop_start()

    def stop(self) -> None:
        self._client.loop_stop()
        self._client.disconnect()

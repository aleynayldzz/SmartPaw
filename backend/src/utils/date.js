function toCalendarDateString(value) {
  if (value == null || value === "") return null;
  if (typeof value === "string") {
    const match = value.match(/^(\d{4}-\d{2}-\d{2})/);
    return match ? match[1] : null;
  }
  if (value instanceof Date && !Number.isNaN(value.getTime())) {
    // node-pg DATE sütunlarını yerel gece yarısı Date olarak verir; UTC bileşenleri
    // takvim gününü bir gün geriye kaydırabilir (ör. TR saatinde 17 Haz → UTC 16 Haz).
    const y = value.getFullYear();
    const m = String(value.getMonth() + 1).padStart(2, "0");
    const d = String(value.getDate()).padStart(2, "0");
    return `${y}-${m}-${d}`;
  }
  return String(value).slice(0, 10);
}

module.exports = {
  toCalendarDateString
};

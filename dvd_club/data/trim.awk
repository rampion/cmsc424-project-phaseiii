# remove everything but the data
BEGIN { s = 0 }
/^-+	+-+$/ { s = 1 }
/^-+$/ { s = 0 }
/^[^-]/ { if (s) print }
/^$/ { if (s) print }

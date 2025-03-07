echo "{
  \"modName\":\"$1\",
  \"p0\":\"$2\",
  \"p1\":\"$3\",
  \"p2\":\"$4\",
  \"p3\":\"$5\",
  \"p4\":\"$5\"
}"
curl http://localhost:8181/call -H "Content-Type: application/json" -d "{
  \"modName\":\"$1\",
  \"p0\":\"$2\",
  \"p1\":\"$3\",
  \"p2\":\"$4\",
  \"p3\":\"$5\",
  \"p4\":\"$5\"
}"

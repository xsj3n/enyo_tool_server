if [ -d "venv/" ]; then
  source venv/bin/activate
else
  python -m venv venv/
fi

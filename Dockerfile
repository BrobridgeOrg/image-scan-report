FROM registry.suse.com/bci/python:3.13

RUN zypper --non-interactive refresh \
    && zypper --non-interactive install --no-recommends \
        libpango-1_0-0 \
        libcairo2 \
        libgdk_pixbuf-2_0-0 \
        suse-fonts \
    && fc-cache -f \
    && zypper clean --all

WORKDIR /opt/suse-security-report

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

ENTRYPOINT ["python3", "main.py"]

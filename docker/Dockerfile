# Pin the base image tag and update it intentionally. Do not use "latest".
FROM hashicorp/http-echo:1.0.0

# Default args, overrideable at runtime via CMD or Helm values.
CMD ["-text=Hello from EKS"]

EXPOSE 5678

# STEP 86.1 Security Deployment Hotfix

This hotfix addresses restart loops caused by overly aggressive container capability dropping on Nginx containers and changes inherited host port bindings for Postgres, backend-nginx, and ai-engine to localhost-only bindings for local QA.

It keeps the edge Nginx available on port 80.

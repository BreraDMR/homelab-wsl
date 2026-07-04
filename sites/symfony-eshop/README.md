# symfony-eshop (deploy wrapper)

Self-contained production deployment of
[BreraDMR/symfony-eshop](https://github.com/BreraDMR/symfony-eshop) for the homelab.

- App code is cloned into `./app` (gitignored, its own repo).
- Secrets live in `.env` (gitignored, see `.env.example`).
- Stack: php-fpm + nginx + postgres + an ngrok tunnel serving a stable free domain.

## Deploy / update

```bash
cp .env.example .env            # fill NGROK_AUTHTOKEN and APP_SECRET
git clone https://github.com/BreraDMR/symfony-eshop app   # or: git -C app pull
docker compose -f deploy.compose.yaml up -d --build
docker exec eshop-php composer install --no-interaction
docker exec eshop-php php bin/console doctrine:migrations:migrate -n
docker exec eshop-php php bin/console doctrine:fixtures:load -n --env=dev
docker exec eshop-php chmod -R 777 var
bash set-admin-pass.sh "<admin-password>"
```

Public URL: https://footer-phoenix-nemesis.ngrok-free.dev

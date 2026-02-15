# RUNBOOK — Cockpit Multiagentes (VPS)

## 0) Pré-requisitos
- Ubuntu/Debian com acesso root/sudo.
- DNS opcional já apontado (para SSL):
  - `painel.seudominio.com` -> IP da VPS
  - `api.seudominio.com` -> IP da VPS
- Monorepo com `docker-compose.yml` e `.env.example`.

## 1) Bootstrap da VPS
Executa criação do `/opt/cockpit`, permissões e Docker/Compose.

```bash
sudo bash infra/scripts/bootstrap_vps.sh
```

### Resultado esperado
- `/opt/cockpit` criado com permissão `750`.
- Docker e Compose disponíveis.
- Código sincronizado em `/opt/cockpit/app`.
- `.env` criado a partir do `.env.example` **sem segredos preenchidos**.

### Falhas comuns + ação corretiva mínima
- `Docker Compose não encontrado`: reinstalar Docker e confirmar plugin (`docker compose version`).
- `.env.example não encontrado`: confirmar que o monorepo já foi entregue com esse arquivo.

---

## 2) Configuração de ambiente
Edite os segredos diretamente em `/opt/cockpit/app/.env`.

```bash
sudoedit /opt/cockpit/app/.env
```

> Não registrar segredos em logs, git ou histórico compartilhado.

---

## 3) Deploy da stack (painel + API + workers + db + redis)
```bash
sudo bash infra/scripts/deploy_stack.sh
```

### Falhas comuns + ação corretiva mínima
- `docker-compose.yml não encontrado`: validar caminho em `COCKPIT_DIR`.
- `.env ausente`: criar via `.env.example` e preencher variáveis obrigatórias.

---

## 4) Nginx reverse proxy (opcional com domínio)
Instala e aplica proxy para painel/API.

```bash
sudo apt-get update
sudo apt-get install -y nginx
sudo cp infra/nginx/cockpit.conf.template /etc/nginx/sites-available/cockpit.conf
sudo sed -i 's/seudominio.com/SEU_DOMINIO_REAL/g' /etc/nginx/sites-available/cockpit.conf
sudo ln -sf /etc/nginx/sites-available/cockpit.conf /etc/nginx/sites-enabled/cockpit.conf
sudo nginx -t
sudo systemctl reload nginx
```

### Falhas comuns + ação corretiva mínima
- `nginx -t` falha: corrigir `server_name`/sintaxe e revalidar.
- 502 Bad Gateway: confirmar portas locais (3000 painel / 8000 API) e containers ativos.

---

## 5) SSL com Certbot (se DNS já apontado)
```bash
sudo apt-get install -y certbot python3-certbot-nginx
sudo certbot --nginx -d painel.seudominio.com -d api.seudominio.com
sudo certbot renew --dry-run
```

### Falhas comuns + ação corretiva mínima
- Falha de challenge: verificar DNS e liberar portas 80/443 no firewall.

---

## 6) Health-check pós deploy
```bash
sudo bash infra/scripts/healthcheck.sh
```

Valida:
- API `/health`
- abertura do painel
- `redis-cli ping` -> `PONG`
- `pg_isready` no serviço de banco

### Falhas comuns + ação corretiva mínima
- API/painel indisponíveis: revisar `docker compose logs` e variáveis no `.env`.
- Redis/DB falham: conferir nomes dos serviços (`REDIS_SERVICE`, `DB_SERVICE`).

---

## 7) Rotinas operacionais (backup + limpeza)

### 7.1 Backup diário do Postgres
```bash
sudo crontab -e
```
Adicionar:
```cron
0 2 * * * /bin/bash /opt/cockpit/app/infra/scripts/backup_postgres.sh >> /var/log/cockpit_backup_postgres.log 2>&1
```

### 7.2 Backup diário de storage (imagens/artefatos)
```cron
30 2 * * * /bin/bash /opt/cockpit/app/infra/scripts/backup_storage.sh >> /var/log/cockpit_backup_storage.log 2>&1
```

### 7.3 Limpeza de temporários
```cron
0 3 * * * /bin/bash /opt/cockpit/app/infra/scripts/cleanup_tmp.sh >> /var/log/cockpit_cleanup.log 2>&1
```

### Restore rápido
- Postgres:
```bash
gunzip -c /opt/cockpit/backups/postgres/pg_<db>_<timestamp>.sql.gz | docker compose -f /opt/cockpit/app/docker-compose.yml exec -T db psql -U postgres -d <db>
```
- Storage:
```bash
tar -xzf /opt/cockpit/backups/storage/storage_<timestamp>.tar.gz -C /opt/cockpit/app/
```

---

## 8) Integração GPU/ComfyUI
Registrar endpoint da instância GPU via variáveis de ambiente (ex.: `.env`):
- `COMFYUI_HOST=<ip-ou-dns-da-gpu>`
- `COMFYUI_PORT=8188`

Teste de conexão HTTP:
```bash
COMFYUI_HOST=<host> COMFYUI_PORT=8188 bash infra/scripts/check_comfyui.sh
```

### Falhas comuns + ação corretiva mínima
- Timeout/refused: abrir porta na instância GPU/security group e validar rota da VPS.

---

## 9) Comandos operacionais do dia a dia

### Deploy/update
```bash
cd /opt/cockpit/app
sudo git pull
sudo bash infra/scripts/deploy_stack.sh
```

### Restart
```bash
cd /opt/cockpit/app
sudo docker compose restart
```

### Logs
```bash
cd /opt/cockpit/app
sudo docker compose logs -f --tail=200
```

### Status
```bash
cd /opt/cockpit/app
sudo docker compose ps
```

---

## Registro de mudanças (não destrutivo)
- Todos os scripts evitam sobrescrita silenciosa de `.env`.
- Backups possuem retenção configurável (padrão 14 dias).
- Limpeza atua apenas em arquivos antigos de diretório temporário configurável.

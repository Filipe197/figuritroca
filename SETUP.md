# FiguriTroca — Setup Completo

## 1. Criar projeto no Supabase (gratuito)

1. Acesse https://supabase.com e crie conta
2. Clique "New project"
3. Nome: `figuritroca`
4. Escolha uma senha para o banco
5. Região: South America (São Paulo)
6. Aguarde ~2 min para o projeto inicializar

---

## 2. Executar o Schema SQL

1. No painel do Supabase, vá em **SQL Editor**
2. Clique em "New query"
3. Cole o conteúdo do arquivo `sql/schema.sql`
4. Clique em **Run** (ou Ctrl+Enter)

---

## 3. Criar os Storage Buckets

No Supabase, vá em **Storage > New bucket** e crie 3 buckets:

| Nome          | Público | Uso              | Máx.  |
|---------------|---------|------------------|-------|
| `avatars`     | ✅ Sim  | Fotos de perfil  | 2 MB  |
| `chat-images` | ✅ Sim  | Imagens no chat  | 5 MB  |
| `post-images` | ✅ Sim  | Imagens nos posts| 5 MB  |

Para cada bucket, adicione a policy:
- Leitura: `anon` (público)
- Upload: `authenticated` (usuários logados)

---

## 4. Ativar Realtime

Em **Database > Replication**, ative as tabelas:
- `messages`
- `trades`
- `meet_confirmations`
- `posts`

---

## 5. Pegar as credenciais

Em **Settings > API**:

- **Project URL**: `https://XXXX.supabase.co`
- **anon public key**: `eyJhbGciOi...`

---

## 6. Conectar no index.html

Abra `index.html` e localize as linhas:

```javascript
const SUPABASE_URL = 'https://SEU_PROJETO.supabase.co';
const SUPABASE_KEY = 'SUA_ANON_KEY_AQUI';
```

Substitua pelos seus valores reais.

---

## 7. Deploy no Vercel (gratuito)

### Opção A — Upload direto (mais fácil):
1. Acesse https://vercel.com
2. "Add New Project" → "Browse" → selecione a pasta `figuritroca-full/`
3. Deploy!

### Opção B — Via GitHub:
```bash
cd figuritroca-full
git init
git add .
git commit -m "FiguriTroca v1.0"
# Crie repositório no GitHub chamado figuritroca
git remote add origin https://github.com/SEU_USUARIO/figuritroca.git
git push -u origin main
```
No Vercel: Import from GitHub → selecione o repo → Deploy.

Seu site estará em: `figuritroca.vercel.app`

---

## 8. Instalar como PWA

### Android (Chrome):
- Abra o site → menu (⋮) → "Adicionar à tela inicial"
- Ou aguarde o banner automático

### iPhone (Safari):
- Abra o site → Compartilhar (□↑) → "Adicionar à Tela de Início"

---

## Funcionalidades com Supabase

| Feature               | Status         |
|-----------------------|----------------|
| Cadastro / Login      | ✅ Completo    |
| Perfil com avatar     | ✅ Completo    |
| Upload imagem chat    | ✅ Completo    |
| Upload imagem post    | ✅ Completo    |
| Emoji picker          | ✅ Completo    |
| Figurinhas (ter/falta)| ✅ Banco pronto|
| Matches automáticos   | ✅ View SQL    |
| Trocas                | ✅ Banco pronto|
| Pontos de troca       | ✅ Banco pronto|
| Confirmação evento    | ✅ Banco pronto|
| Posts comunidade      | ✅ Completo    |
| Realtime chat         | ✅ Banco pronto|
| Ranking / Conquistas  | ✅ Banco pronto|

---

## Limites do plano gratuito Supabase

- 500 MB banco de dados
- 1 GB storage (imagens)
- 2 projetos simultâneos
- 50.000 usuários ativos/mês
- Suficiente para lançar e crescer!

---

## Próximos passos sugeridos

1. Adicionar tela de gerenciar figurinhas (marcar ter/faltar)
2. Notificações push (Web Push API)
3. Sistema de avaliação após troca
4. Integração Google Maps real para pontos
5. Painel admin para moderar posts

# Publicar o portfólio no GitHub Pages

O repositório local já está pronto (`git init` + 1º commit feito).
Só falta: **1)** gerar os vídeos leves, **2)** criar o repositório no GitHub, **3)** enviar.

---

## 1. Gerar as versões leves dos vídeos

Os arquivos originais (16 GB) **não vão** para o GitHub — o limite é 100 MB por
arquivo e ~1 GB por repositório. O `.gitignore` já exclui as pastas originais.

```powershell
winget install Gyan.FFmpeg
```

Feche e reabra o PowerShell. Depois, na pasta do projeto:

```powershell
powershell -ExecutionPolicy Bypass -File .\comprimir-videos.ps1
```

Isso cria a pasta `web\` (uns 200–400 MB no total) com os `.mp4` comprimidos
e as miniaturas `.jpg`. Abra o `index.html` no navegador para conferir.

---

## 2. Criar o repositório no GitHub

1. Crie uma conta em https://github.com (se ainda não tiver).
2. Em https://github.com/new crie um repositório **público**, por exemplo
   `portfolio` — **sem** marcar "Add a README".
3. Anote o endereço, algo como `https://github.com/SEU-USUARIO/portfolio.git`.

---

## 3. Enviar os arquivos

Instale o GitHub CLI:

```powershell
winget install GitHub.cli
```

Feche e reabra o PowerShell, então:

```bash
gh auth login
git add web
git commit -m "Vídeos comprimidos + miniaturas"
git branch -M main
git remote add origin https://github.com/SEU-USUARIO/portfolio.git
git push -u origin main
```

---

## 4. Ligar o GitHub Pages

1. No repositório: **Settings → Pages**.
2. Em "Build and deployment", **Source: Deploy from a branch**.
3. Branch: **main**, pasta: **/ (root)** → **Save**.
4. Aguarde ~1 minuto. O site fica em:
   `https://SEU-USUARIO.github.io/portfolio/`

O player é a tag `<video>` nativa: sem logo, sem marca d'água, sem "assistir em
outro site". Vídeo limpo.

---

## Atualizar depois (novos vídeos)

1. Coloque os `.mp4` novos nas pastas de segmento.
2. Rode `comprimir-videos.ps1` de novo (ele só processa o que falta).
3. Adicione o nome do arquivo na lista `FILES` dentro do `index.html`.
4. `git add -A && git commit -m "novos vídeos" && git push`

---

## Se um dia mudar de hospedagem

No topo do `<script>` em `index.html` existe:

```js
const BASE='web/';
```

- `'web/'` → vídeos na pasta `web` do próprio site (padrão, funciona no Pages).
- `''` → usa os arquivos originais nas pastas (pesado, só para teste local).
- `'https://cdn.exemplo.com/'` → se um dia hospedar os vídeos em outro lugar.

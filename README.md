# HepaMap — Araraquara/SP

Rastreamento anônimo de hepatites virais (foco: hepatite B). Projeto de extensão Uniara — Enfermagem.

- `index.html`: formulário público e anônimo (é o link do QR Code). Ele só envia respostas.
- `app.html`: app dos agentes de saúde. Tem login, mapa de focos e as unidades de saúde mais próximas.
- `supabase.sql`: estrutura do banco e regras de acesso.

## Atualizações
- **App:** o Claude envia o código novo para este repositório e muda `version.json`. No app aparece "nova versão" e o botão **Atualizar**.
- **Banco:** cada mudança fica em `migrations/NNN_nome.sql` e é listada em `migrations/index.json`. O administrador clica em **Atualizar** no app e ela é aplicada no Supabase.
- **Instalação (uma única vez):** rodar `INSTALAR_UMA_VEZ.sql` no SQL Editor do Supabase.

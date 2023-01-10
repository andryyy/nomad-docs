# Mutagen job file

This job file must be passed "telegram_bot_token" and "telegram_chat_id" variables **if Telegram notifications should be enabled**:

```bash
nomad run -var telegram_bot_token="123:xyz-xyz" -var telegram_chat_id="-123" sync.nomad
```

Alternatively default values can be assigned on top of the job file.

**Important**: These variables will not be stored encrypted.

```bash
{{#include ../../../../jobs/sync/sync.nomad}}
```

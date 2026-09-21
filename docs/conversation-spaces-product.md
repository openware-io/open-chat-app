# Conversation Spaces & Privacy Boundary (Product)

> Product/business baseline for the four conversation spaces and the privacy
> boundary in `gv_chat_app`. This is the product-owned document for this repo;
> implementation baseline lives in
> [channel-secret-chat.md](channel-secret-chat.md). Server-side semantics are
> documented in `gv_im_server/docs/business/CONVERSATION_TYPES_AND_PRIVACY.md`.

## 1. Core Product Principles

1. **Transport encryption != End-to-end encryption (E2EE)**: cloud
   conversations must clearly state "server can access content"; only secret
   chats may claim E2EE.
2. **Delete / recall = one synchronized delete action**: do not promise to
   revoke copies the other side already saved (screenshots, forwards,
   downloads, local saves are uncontrollable).

## 2. Four Conversation Spaces

| Space | Positioning | Key capabilities | Privacy boundary |
|-------|-------------|------------------|------------------|
| Cloud private (1v1) | everyday multi-device chat | messages, replies, forwards, edit, delete-for-both, cross-device history | server-readable plaintext |
| Cloud group | multi-person collaboration | members, roles, mute, remove, promote, invite links, pins, topics, audit | server-readable plaintext |
| Channel | one-way broadcast | owner publishes, subscribers read; share/notify | server-readable plaintext; only owner posts |
| Secret chat (1v1 only) | high-sensitivity 1v1 | E2EE, safe-code fingerprint, timed self-destruct, no sync to new devices | server stores ciphertext only |

## 3. Message Lifecycle

```
draft → client submit → sending → server ack → delivered → read
                              └────── failed / retry
after send: reply / forward / edit / react / pin / delete
```

- Cloud spaces: server persists and distributes; new devices can sync history.
- Secret chat: devices negotiate keys; server relays ciphertext only; new
  devices get no history/keys; timed destroy starts after the peer reads.

## 4. Delete & Recall Semantics

- **Recall**: sender recalls within the window; server keeps a tombstone so
  sync cursors stay valid; both sides notified via MQ/WebSocket.
- **Delete (for everyone)**: removes the server record and the message on the
  other device(s); already-read/copied local content cannot be revoked
  (boundary copy must state this).

## 5. Privacy Boundary Rules

- Cloud spaces: server-readable, multi-device sync.
- Secret chat: server stores only ciphertext + metadata; new devices have no
  history/keys (recovery flow required); timed destroy counts from peer read,
  then both devices remove the message (no sync to new devices).

## 6. UI Mapping in gv_chat_app

- Chat list shows distinct icons per conversation type
  (`channel`/`secret`/`group`/`private`).
- Channel rooms are read-only for subscribers; owner gets publish controls.
- Secret chat rooms show a lock badge, safe-code view/copy, self-destruct
  policy selector, and the "not synced to new devices" hint.

## 7. Feature Status

| Capability | Status |
|------------|--------|
| Cloud private / group basics | Done (pre-existing) |
| Channel (create/subscribe/roles/read-only) | Done |
| Secret chat session (handshake/safe-code/destroy policy) | Done |
| Device key (register/renew/restore) | Done (X25519 keypair + registration) |
| Ciphertext storage & cursor pull | Done (AES-GCM ciphertext via `/secret-messages`) |
| Client-side E2EE encryption/decryption | **Done** (X25519 ECDH + AES-GCM; verified end-to-end on production) |
| Timed destroy engine (server scan + client local destroy) | Done (server-side; client hides on `destroyed`/`destroyAt`) |
| Edit / react / pin / invite links / topics / audit | Backlog |

## 8. Non-Promises

- No promise to revoke local copies already saved by the peer.
- Cloud conversations never claim E2EE; only secret chats do.

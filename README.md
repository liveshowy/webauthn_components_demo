# WebauthnComponents Demo

This repo is a reference implementation of the `:webauthn_components` package on [Hex.pm](https://hex.pm/packages/webauthn_components).

## Resources

- Hex.pm: [WebauthnComponents](https://hex.pm/packages/webauthn_components)
- HexDocs: [WebAuthnComponents](https://hexdocs.pm/webauthn_components/)
- GitHub: [webauthn_components](https://github.com/liveshowy/webauthn_components)
- Elixir Forum: [WebAuthnComponents](https://elixirforum.com/t/webauthnlivecomponent-passwordless-auth-for-liveview-apps/49941/18)

## Design Decisions

As a starting point, much of the code in this repo was generated with standard mix tasks:

```elixir
mix phx.new webauthn_components_demo --binary-id
...
mix phx.gen.auth Accounts User users --binary-id --live
```

These tasks establish the LiveViews and schemas for user registration and authentication with magic email links, as well as server-backed session management. Users may also create a password from the user settings page after successful authentication. This approach enforces email verification, which is a common real-world concern.

## Up & Running

To start your Phoenix server:

* Run `mix setup` to install and setup dependencies
* Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

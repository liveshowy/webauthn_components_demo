# WebauthnComponents Demo

This repo is a reference implementation of the `:webauthn_components` package on [Hex.pm](https://hex.pm/packages/webauthn_components).

## Resources

- Hex.pm: [WebauthnComponents](https://hex.pm/packages/webauthn_components)
- HexDocs: [WebAuthnComponents](https://hexdocs.pm/webauthn_components/)
- GitHub: [webauthn_components](https://github.com/liveshowy/webauthn_components)
- Elixir Forum: [WebAuthnComponents](https://elixirforum.com/t/webauthnlivecomponent-passwordless-auth-for-liveview-apps/49941/18)

## Getting Started

If Erlang, Elixir, and Postgres are installed as OS dependencies, you may skip to [Phoenix Server](#phoenix-server) to get the application up and running. If you encounter Postgres connection errors, you may need to update the repo credentials in [`./config`](./config/).

### Development Container

For your convenience, a development container is provided in [`./.devcontainer`](./.devcontainer).

VS Code developers may use the [Remote Containers](https://www.google.com/search?client=safari&rls=en&q=vs+code+remote+container&ie=UTF-8&oe=UTF-8) extension to quickly launch the development environment. When using VS Code, `mix deps.get` & `mix ecto.setup` will be run automatically after the container is up and running.

Developers using any other IDE may also start containers using Docker Compose ([docs](https://docs.docker.com/engine/reference/commandline/compose_up/)).

### Phoenix Server

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Start Phoenix endpoint with `mix phx.server` or inside IEx with `iex -S mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Learn more

  * Official website: https://www.phoenixframework.org/
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Forum: https://elixirforum.com/c/phoenix-forum
  * Source: https://github.com/phoenixframework/phoenix

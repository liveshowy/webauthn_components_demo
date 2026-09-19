defmodule WebauthnComponentsDemo.Repo do
  use Ecto.Repo,
    otp_app: :webauthn_components_demo,
    adapter: Ecto.Adapters.Postgres
end

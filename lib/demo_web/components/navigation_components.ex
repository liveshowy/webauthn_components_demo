defmodule DemoWeb.NavigationComponents do
  @moduledoc """
  Components for navigating the application.
  """
  use Phoenix.Component
  use DemoWeb, :verified_routes

  embed_templates "/navigation/*"

  alias Demo.Identity.User

  attr :current_user, User, required: true

  def navbar(assigns)

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(href navigate patch method)
  slot :inner_block, required: true

  def nav_link(assigns)
end

defmodule DemoWeb.SettingsLiveTest do
  @moduledoc false
  use DemoWeb.ConnCase, async: true
  import Phoenix.LiveViewTest
  alias Demo.IdentityFixtures

  defp route, do: ~p"/settings"

  setup %{conn: conn} do
    conn =
      IdentityFixtures.user_fixture()
      |> IdentityFixtures.register_default_key()
      |> IdentityFixtures.sign_in_user(conn)

    %{conn: conn}
  end

  describe "mount & render" do
    test "includes expected elements", %{conn: conn} do
      assert {:ok, view, html} = live(conn, route())

      # Passkey Form
      assert has_element?(view, "form[phx-change='update-form'][phx-submit]")

      # Registered Passkeys Table
      assert has_element?(view, "ul[role='list']")
      assert has_element?(view, "ul > li")
      assert html =~ "Key Name"
      assert html =~ "Last Used"
    end
  end

  describe "handle_event: update-form" do
    test "results in updated form", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())

      assert view
             |> element("form[phx-change='update-form']")
             |> render_change(%{label: "Test Label"})

      assert has_element?(view, "input[type='text'][value='Test Label']")
    end
  end

  # Since some events are handled internally by the RegistrationComponent,
  # we need to mock the messages sent from the component to the LiveView.

  describe "handle_info: registration_successful" do
    test "results in a new user key", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      label = "1Password Key"
      assert render_change(view, "update-form", %{label: label})
      key = IdentityFixtures.user_key_attrs()

      msg = {:registration_successful, key: key}
      send(view.pid, msg)
      render(view)

      assert has_element?(view, "#flash", "Succesfully registered new key")
      assert has_element?(view, "div", label)
    end

    test "duplicate key name", %{conn: conn} do
      {:ok, view, _html} = live(conn, route())
      label = "1Password Key"
      assert render_change(view, "update-form", %{label: label})
      key = IdentityFixtures.user_key_attrs()

      msg = {:registration_successful, key: key}
      send(view.pid, msg)
      render(view)

      assert has_element?(view, "#flash", "Succesfully registered new key")
      assert has_element?(view, "div", label)
    end
  end
end

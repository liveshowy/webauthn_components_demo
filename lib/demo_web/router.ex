defmodule DemoWeb.Router do
  use DemoWeb, :router

  (
    alias DemoWeb.SessionHooks.AssignUser
    alias DemoWeb.SessionHooks.RequireUser
    import DemoWeb.Session, only: [fetch_current_user: 2]
  )

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {DemoWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :fetch_current_user
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DemoWeb do
    pipe_through :browser

    get "/", PageController, :home
  end

  # HTTP controller routes
  scope "/", DemoWeb do
    pipe_through :browser

    post "/session", Session, :create
    delete "/session", Session, :delete
  end

  # Unprotected LiveViews
  live_session :guest, on_mount: [AssignUser] do
    scope "/", DemoWeb do
      pipe_through :browser

      live "/sign-in", AuthenticationLive
    end
  end

  # Protected LiveViews
  live_session :authenticated, on_mount: [AssignUser, RequireUser] do
    scope "/", DemoWeb do
      pipe_through :browser

      # Example
      # live "/room/:room_id", RoomLive
      live "/settings", SettingsLive
    end
  end

  # Other scopes may use custom stacks.
  # scope "/api", DemoWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:demo, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: DemoWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

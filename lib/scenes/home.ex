defmodule ElixiumWallet.Scene.Home do
  use Scenic.Scene
  alias Scenic.Graph
  import Scenic.Primitives
  alias Scenic.ViewPort

  alias ElixiumWallet.Component.Nav
  alias ElixiumWallet.Component.Notes
  alias ElixiumWallet.Utilities

  @theme Application.get_env(:elixium_wallet, :theme)

  @tips """
        Welcome to Elixium Wallet!
        Here you can Send, Receive your XEX, generate new keys
        and check the status of the Elixium Network

        We have finally reached our first test net! please enjoy and
        let us now via our telegram channel of any bugs you find!
        """

@news_feed """
    Fast transactions, #anonymized network, and #Javascript contracts -- the perfect trio.
    We're building something you won't want to miss out on, so join us on the journey!
    http://t.me/elixiumnetwork  #blockchain #Elixium
  """

  @path :code.priv_dir(:elixium_wallet)
               |> Path.join("/static/images/Logo.png")
  @hash Scenic.Cache.Hash.file!( @path, :sha )



  @graph Graph.build(font: :roboto, font_size: 24, clear_color: {10, 10, 10})
         |> text("Elixium News", fill: @theme.nav, font_size: 26, translate: {150, 70})
         |> text(@news_feed, fill: @theme.nav, font_size: 20, translate: {200, 120})
         |> text("Welcome!", fill: @theme.nav, font_size: 26, translate: {200, 200})
         |> text(@tips, fill: @theme.nav, font_size: 20, translate: {200, 220})
         |> Nav.add_to_graph(__MODULE__)
         |> rect({10, 30}, fill: @theme.nav, translate: {130, 110})
         |> circle(10, fill: @theme.nav, stroke: {0, :clear}, t: {130, 110})
         |> circle(10, fill: @theme.nav, stroke: {0, :clear}, t: {130, 140})




  def init(_, opts) do
    Scenic.Cache.File.load(@path, @hash)
    push_graph(@graph)
    {:ok, %{graph: @graph, viewport: opts[:viewport]}}
  end

  def filter_event({:click, :btn_balance}, _, %{viewport: vp} = state) do
    ViewPort.set_root(vp, {ElixiumWallet.Scene.Balance, nil})
    {:continue, {:click, :btn_balance}, state}
  end

  def filter_event({:click, :btn_stats}, _, %{viewport: vp} = state) do
    ViewPort.set_root(vp, {ElixiumWallet.Scene.Stats, nil})
    {:continue, {:click, :btn_stats}, state}
  end


end

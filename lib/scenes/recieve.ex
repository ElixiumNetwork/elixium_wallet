defmodule ElixWallet.Scene.Recieve do

    use Scenic.Scene
    alias Scenic.Graph
    alias ExixWallet.QRCode
    import Scenic.Primitives
    import Scenic.Components

    alias ElixWallet.Component.Nav

    @settings Application.get_env(:elix_wallet, :settings)

    @algorithm :ecdh
    @sigtype :ecdsa
    @curve :secp256k1
    @hashtype :sha256


    def init(_, _opts) do

      graph = push()
      update_all(graph)
      state = %{graph: graph}
      {:ok, state}
    end

    defp push() do
      pub_key = get_keys()
      qr_path = @settings.unix_key_location<>"/qr.png"
      qr_hash =  Scenic.Cache.Hash.file!( qr_path, :sha )
      Scenic.Cache.File.load(qr_path, qr_hash)
      graph = Graph.build(font: :roboto, font_size: 24)
             |> text("RECEIVE", id: :title, font_size: 26, translate: {350, 100})
             |> text("Your Receiving address:", font_size: 24, height: 15, width: 400, translate: {200, 135})
             |> rect(
               {650, 50},
               fill: :clear,
               stroke: {2, {255,255,255}},
               id: :border,
               join: :round,
               translate: {90, 150}
             )
             |> text("Or Scan QR Code", font_size: 24, height: 15, width: 400, translate: {200, 275})
             |> rect(
               {305, 305},
               stroke: {0, :clear},
               id: :image,
               translate: {250, 290}
             )
             |> text(pub_key,id: :pub_address, font_size: 24, height: 15, width: 400, translate: {100, 180})
             |> button("Copy", id: :btn_copy, width: 80, height: 46, theme: :dark, translate: {150, 200})
             |> Nav.add_to_graph(__MODULE__)
      push_graph(graph)
      state = %{graph: graph}
      graph
    end

    defp get_keys() do
      key_pair = Elixium.KeyPair.create_keypair
      with {:ok, public} <- create_keyfile(key_pair) do
        pub = Elixium.KeyPair.address_from_pubkey(public)
        qr_code_png = pub
                    |> EQRCode.encode()
                    |> EQRCode.png(width: 300)

        File.write!(@settings.unix_key_location<>"/qr.png", qr_code_png, [:binary])
          pub
      end
    end

    defp update_all(graph) do
      qr_path = @settings.unix_key_location<>"/qr.png"
      qr_hash =  Scenic.Cache.Hash.file!( qr_path, :sha )
      Scenic.Cache.put(qr_path, qr_hash)
      graph = graph |> Graph.modify(:image, &update_opts(&1, fill: {:image, qr_hash})) |> push_graph()
    end

    defp create_keyfile({public, private}) do
      case :os.type do
        {:unix, _} -> check_and_write(@settings.unix_key_location, {public, private})
        {:win32, _} -> check_and_write(@settings.win32_key_location, {public, private})
      end
    end

    defp check_and_write(full_path, {public, private}) do
      if !File.dir?(full_path), do: File.mkdir(full_path)
      pub_hex = Elixium.KeyPair.address_from_pubkey(public)
      with :ok <- File.write!(full_path<>"/#{pub_hex}.key", private) do
        {:ok, public}
      end
    end

    def filter_event({:click, :btn_copy}, _, %{graph: graph} = state) do
      address = Graph.get!(graph, :pub_address).data
      
      :os.cmd('echo #{address} | xclip -selection c')
      {:continue, {:click, :btn_copy}, state}
    end

  end

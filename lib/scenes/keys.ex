defmodule ElixWallet.Scene.Keys do

    use Scenic.Scene
    alias Scenic.Graph
    alias ElixWallet.Component.Notes
    alias Elixium.KeyPair
    alias Scenic.ViewPort
    import Scenic.Primitives
    import Scenic.Components

    alias ElixWallet.Component.Nav

    @settings Application.get_env(:elix_wallet, :settings)
    @notes "Random Note"
    @success "Generated Key Pair"

    @bird_path :code.priv_dir(:elix_wallet)
               |> Path.join("/static/images/cyanoramphus_zealandicus_1849.jpg")
    @bird_hash Scenic.Cache.Hash.file!( @bird_path, :sha )
    @parrot_path :code.priv_dir(:elix_wallet)
                 |> Path.join("/static/images/Logo.png")
    @parrot_hash Scenic.Cache.Hash.file!( @parrot_path, :sha )

    @parrot_width 480
    @parrot_height 270
    @bird_width 100
    @bird_height 128

    @body_offset 80

    @line {{0, 0}, {60, 60}}

    @notes """
      Generate, Import & Backup Your Keys
    """

    @graph Graph.build(font: :roboto, font_size: 24, theme: :dark)
           |> group(
             fn g ->
               g
               |> rect(
                 {@parrot_width, @parrot_height},
                 id: :parrot,
                 fill: {:image, {@parrot_hash, 50}},
                translate: {135, 150}
                 )
               |> text("", translate: {150, 150}, id: :event)
               |> text("", font_size: 12, translate: {5, 180}, id: :hint)
               |> text("KEY CONFIGURATION", id: :small_text, font_size: 26, translate: {275, 100})
               |> button("Generate Key", id: :btn_generate, width: 120, height: 46, theme: :dark, translate: {90, 200})
               |> button("Import Key", id: :btn_import, width: 120, height: 46, theme: :dark, translate: {90, 350})

             end)
           # Nav and Notes are added last so that they draw on top
           |> Nav.add_to_graph(__MODULE__)
           |> Notes.add_to_graph(@notes)


    def init(_, opts) do
      viewport = opts[:viewport]
      {:ok, %ViewPort.Status{size: {vp_width, vp_height}}} = ViewPort.info(viewport)

      Scenic.Cache.File.load(@parrot_path, @parrot_hash)


          position = {
            vp_width / 2 - @parrot_width / 2,
            vp_height / 2 - @parrot_height / 2
          }

      Scenic.Cache.File.load(@parrot_path, @parrot_hash)

        push_graph(@graph)



      {:ok, %{graph: @graph, viewport: opts[:viewport]}}
    end



    def filter_event({:click, :btn_import}, _, %{viewport: vp} = state) do
      IO.puts "Button Clicked Import"
      IO.inspect state
      ViewPort.set_root(vp, {ElixWallet.Scene.ImportKey, nil})
    end

    def filter_event({:click, :btn_generate}, _, %{graph: graph}) do
      IO.inspect graph
      IO.puts "Button Clicked Generate"
      mnemonic = ElixWallet.Advanced.generate() |> IO.inspect
      IO.puts "Back to Entropy"
      ElixWallet.Advanced.to_entropy(mnemonic) |> IO.inspect
      with {:ok, mnemonic} <- create_keyfile(Elixium.KeyPair.create_keypair) do
        graph =
          graph
          |> Graph.modify(:event, &text(&1, "Succesfully Generated the Key, Please write down the mnemonic"))
          |> Graph.modify(:hint, &text(&1, mnemonic))
          |> push_graph()
#
      {:continue, {:click, :btn_generate}, graph}
    end
    end

    defp create_keyfile({public, private}) do
      case :os.type do
        {:unix, _} -> check_and_write(@settings.unix_key_location, {public, private})
        {:win32, _} -> check_and_write(@settings.win32_key_location, {public, private})
      end
    end

    def filter_event(event, _, graph) do
      #if event = {:click, :btn_generate} do
      #  with :ok <- create_keyfile(Elixium.KeyPair.create_keypair) do
      #    IO.inspect "Worked ok"
      #  graph =
      #    graph
      #    |> Graph.modify(:event, &text(&1, "Succesfully Generated the Key"))
      #    |> push_graph()
#
    #  {:continue, event, graph}
  #  end
    #end
    end

    defp check_and_write(full_path, {public, private}) do
      mnemonic = ElixWallet.Advanced.from_entropy(private)
      if !File.dir?(full_path), do: File.mkdir(full_path)
      pub_hex = Base.encode16(public)
      with :ok <- File.write!(full_path<>"/#{pub_hex}.key", private) do
        {:ok, mnemonic}
      end
    end

  

  end

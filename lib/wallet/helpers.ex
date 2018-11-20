defmodule ElixWallet.Helpers do
  alias Elixium.Transaction
  alias Elixium.Utilities
  alias Elixium.Store.Utxo
  alias Elixium.KeyPair
  alias Decimal, as: D
  require IEx

  @settings Application.get_env(:elix_wallet, :settings)

  def new_transaction(address, amount, desired_fee)  do
    amount = D.from_float(amount)
    desired_fee = D.from_float(desired_fee)

    case find_suitable_inputs(D.add(amount, desired_fee)) do
      :not_enough_balance -> :not_enough_balance
      inputs ->
        designations = [%{amount: amount, addr: address}]

        designations =
          case D.cmp(Transaction.sum_inputs(inputs), D.add(amount, desired_fee)) do
            :gt ->
              # Since a UTXO is fully used up when we put it in a new transaction, we must create a new output
              # that credits us with the change
              [%{amount: D.sub(Transaction.sum_inputs(inputs), D.add(amount, desired_fee)), addr: address} | designations]
            :lt -> designations
            :eq -> designations
          end

        tx =
          %Transaction{
            designations: designations,
            inputs: inputs,
            timestamp: DateTime.utc_now |> DateTime.to_string
          }

        # The transaction ID is just the merkle root of all the inputs, concatenated with the timestamp
        id =
          Transaction.calculate_hash(tx) <> tx.timestamp
          |> Utilities.sha_base16()

        tx = %{tx | id: id}
        Map.merge(tx, Transaction.calculate_outputs(tx))
    end
  end

  @doc """
    Return all UTXOs that are owned by the given public key
  """
  @spec find_pubkey_utxos(String.t) :: list
  def find_pubkey_utxos(public_key) do
    #GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:retrieve_wallet_utxos, []})
  end

  def setup do
    :ets.insert(:scenic_cache_key_table, {"current_balance", 1, 0.0})
  end

  def get_balance() do
    raw_balance =
      GenServer.call(:"Elixir.Elixium.Store.UtxoOracle", {:retrieve_wallet_utxos, []}, 20000)
      |> Enum.reduce(0, fn utxo, acc -> acc + D.to_float(utxo.amount) end)
    :ets.insert(:scenic_cache_key_table, {"current_balance", 1, raw_balance/1})
  end


######DEFUNKT
  def find_wallet_utxos do
    case File.ls(@settings.unix_key_location) do
      {:ok, keyfiles} ->
        Enum.flat_map(keyfiles, fn file ->
          {pub, priv} = KeyPair.get_from_file(@settings.unix_key_location <> "/#{file}")

          pub
          |> KeyPair.address_from_pubkey
          |> find_pubkey_utxos()
          |> Enum.map( &(Map.merge(&1, %{signature: KeyPair.sign(priv, &1.txoid) |> Base.encode16})) )
        end)
      {:error, :enoent} -> IO.puts "No keypair file found"
    end
  end

  @doc """
    Take all the inputs that we have the necessary credentials to utilize, and then return
    the most possible utxos whos amounts add up to the amount passed in
  """
  @spec find_suitable_inputs(number) :: list
  def find_suitable_inputs(amount) do
    find_wallet_utxos()
    |> Enum.sort(&(:lt == D.cmp(&1.amount, &2.amount)))
    |> take_necessary_utxos(amount)
  end

  defp take_necessary_utxos(utxos, amount), do: take_necessary_utxos(utxos, [], amount)

  defp take_necessary_utxos(utxos, chosen, amount) do
    if D.cmp(amount, 0) == :gt do
      if utxos == [] do
        :not_enough_balance
      else
        [utxo | remaining] = utxos
        take_necessary_utxos(remaining, [utxo | chosen], D.sub(amount, utxo.amount))
      end
    else
      chosen
    end
  end
end
defmodule Twitter do
  alias Twitter.Server.Engine
  alias Twitter.Client.User
  alias Twitter.Client.UserSupervisor

  def main(args \\ []) do    
    args
    |> parse_string

    receive do   
        
    end    
  end

  defp parse_string(args) do    
    type = Enum.at(args,0)  
    local_address = find_local_address()     
    if type == "server" do
      server_name = :"twitter-server@#{local_address}" 
      num_users = String.to_integer(Enum.at(args,1))      
      Engine.start_link            
      start_distributed(server_name)
      {:ok, _} = UserSupervisor.start_link
      simulate_users(num_users, num_users, server_name, local_address)
      user_login(1, num_users, num_users, server_name, local_address)  
      
      start_user_tweet_loop(num_users, server_name, local_address)
      spawn fn -> hit_counter(0, server_name)  end    
      :timer.sleep(3000)
      infinite_tweet_loop(num_users, server_name, local_address)
    else
      server_address = Enum.at(args,1)
      server_name = :"twitter-server@#{server_address}" 
      api = Enum.at(args,2)
      case api do
        "automatic" ->          
          local_address = find_local_address()
          client_name = generate_client_name("user", local_address)          
          start_distributed(client_name)
          IO.inspect Node.connect(:"#{server_name}")
          IO.inspect "Your Username is #{client_name}"
          {:ok, _} = UserSupervisor.start_link
          UserSupervisor.add_user(client_name, 1, 1)

          case GenServer.call({:twitter_engine, server_name}, {:user_register, client_name, "password", client_name}) do
            {_, msg} -> IO.inspect msg
          end
           
          case GenServer.call({:twitter_engine, server_name}, {:user_login, client_name, client_name}) do
            {_, msg} -> IO.inspect msg
          end
    
          follow1 = :"user1@#{server_address}"
          follow2 = :"user2@#{server_address}"
          case GenServer.call({:twitter_engine, server_name}, {:follow, follow1, client_name, client_name}) do
            {_, msg} -> IO.inspect msg
          end

          case GenServer.call({:twitter_engine, server_name}, {:follow, follow2, client_name, client_name}) do
            {_, msg} -> IO.inspect msg
          end
        
        "register" ->          
          local_address = find_local_address()
          user = Enum.at(args,3)
          client_name = :"#{user}@#{local_address}"         
          start_distributed(client_name)
          Node.connect(:"#{server_name}")
          IO.inspect "Your Username is #{client_name}"
          {:ok, _} = UserSupervisor.start_link
          UserSupervisor.add_user(client_name, 1, 1)
          case GenServer.call({:twitter_engine, server_name}, {:user_register, client_name, "password", client_name}) do
            {_, msg} -> IO.inspect msg
          end     
        "login" ->
          client_name = String.to_atom(Enum.at(args,3))
          start_distributed(client_name)
          Node.connect(:"#{server_name}")
          {:ok, _} = UserSupervisor.start_link
          UserSupervisor.add_user(client_name, 1, 1)
          case GenServer.call({:twitter_engine, server_name}, {:user_login, client_name, client_name}) do
            {_, msg} -> IO.inspect msg
          end
        "logout" ->
          client_name = String.to_atom(Enum.at(args,3))
          start_distributed(client_name)
          Node.connect(:"#{server_name}")
          case GenServer.call({:twitter_engine, server_name}, {:user_logout, client_name, client_name}) do
            {_, msg} -> IO.inspect msg
          end
        "follow" ->
          follower = String.to_atom(Enum.at(args,3))
          following = String.to_atom(Enum.at(args,4))
          start_distributed(follower)
          Node.connect(:"#{server_name}")
          {:ok, _} = UserSupervisor.start_link
          UserSupervisor.add_user(follower, 1, 1)          
          case GenServer.call({:twitter_engine, server_name}, {:follow, following, follower, follower}) do
            {_, msg} -> IO.inspect msg
            _ -> IO.inspect ""
          end
        "send_tweet" ->
          client_name = String.to_atom(Enum.at(args,3))
          tweet = Enum.at(args,4)
          start_distributed(client_name)
          Node.connect(:"#{server_name}")
          {:ok, _} = UserSupervisor.start_link
          UserSupervisor.add_user(client_name, 1, 1)
          GenServer.cast({:twitter_engine, server_name}, {:send_tweet, client_name, client_name, tweet})
        "receive_tweet" ->
          client_name = String.to_atom(Enum.at(args,3))
          tweet = Enum.at(args,4)
          start_distributed(client_name)
          Node.connect(:"#{server_name}")
          GenServer.cast({:twitter_engine, server_name}, {:receive_tweet, client_name, ""})
        "search_hashtag" ->
          hashtag = Enum.at(args,3)     
          local_address = find_local_address()
          client_name = generate_client_name("user", local_address)          
          start_distributed(client_name)  
          Node.connect(:"#{server_name}")          
          case GenServer.call({:twitter_engine, server_name}, {:search_hashtag, hashtag}) do
            {_, msg} -> 
              IO.inspect "------------------------"
              IO.inspect "Tweets for hashtag #{hashtag}"
              IO.inspect msg
              IO.inspect "------------------------" 
          end
        "search_usertweet" ->
          user = Enum.at(args,3) 
          local_address = find_local_address()
          client_name = generate_client_name("user", local_address)          
          start_distributed(client_name)
          Node.connect(:"#{server_name}")
          case GenServer.call({:twitter_engine, server_name}, {:search_user, user}) do
            {_, msg} -> 
              IO.inspect "------------------------"
              IO.inspect "Tweets for search user #{user}"
              IO.inspect msg
              IO.inspect "------------------------"
          end                 
      end 

    end
  end

  def hit_counter(count, server_name) do
     co = GenServer.call({:twitter_engine, server_name}, {:hit_counter})
     IO.inspect "++++++++++++++++++++++++++++++++"
     diff = co - count
     IO.inspect("Hit Count = #{diff}")
     :timer.sleep(10000)
     hit_counter(co, server_name)
  end
  
  def start_user_tweet_loop(num_users, server_name, local_address) do
    if num_users > 0 do
      username = :"user#{num_users}@#{local_address}"      
      GenServer.cast({username, server_name}, {:send_tweet, "#{username} First Tweet", local_address, server_name})
      start_user_tweet_loop(num_users - 1, server_name, local_address)
    end
  end

  def infinite_tweet_loop(num_users, server_name, local_address) do
    predefined_hashtags = {"#dos ", "#twitter ", "#fun ", "#project ", "#test "}
    predefined_usernames = {"@user1@#{local_address}", "@user2@#{local_address}", "@user3@#{local_address}", "@user4@#{local_address}", "@user5@#{local_address}"}
    predefined_tweets = {"First tweet ", "Second tweet ", "Third tweet ", "Fourth tweet ", "Fifth tweet "}
    #start_sending_tweets(num_users, server_name, local_address, predefined_hashtags, predefined_usernames, predefined_tweets)
    start_sending_retweets(num_users, server_name, local_address) 
    
    case GenServer.call({:twitter_engine, server_name}, {:search_hashtag, "#dos"}) do
      {_, msg} -> 
        IO.inspect "------------------------"
        IO.inspect "Tweets for hashtag #dos"
        IO.inspect msg
        IO.inspect "------------------------"
    end
    case GenServer.call({:twitter_engine, server_name}, {:search_hashtag, "#twitter"}) do
      {_, msg} -> 
        IO.inspect "------------------------"
        IO.inspect "Tweets for hashtag #twitter"
        IO.inspect msg
        IO.inspect "------------------------"
    end
    case GenServer.call({:twitter_engine, server_name}, {:search_user, "@user1@#{local_address}"}) do
      {_, msg} -> 
        IO.inspect "------------------------"
        IO.inspect "Tweets for search user @user1@#{local_address}"
        IO.inspect msg
        IO.inspect "------------------------"
    end
    case GenServer.call({:twitter_engine, server_name}, {:search_user, "@user2@#{local_address}"}) do
      {_, msg} -> 
        IO.inspect "------------------------"
        IO.inspect "Tweets for search user @user2@#{local_address}"
        IO.inspect msg
        IO.inspect "------------------------"
    end
    :timer.sleep(5000)
    infinite_tweet_loop(num_users, server_name, local_address)
  end

  def simulate_users(count, num_count, server_name, local_address) do
    if count > 0 do
      #username = generate_client_name("user#{count}", local_address)
      username = :"user#{count}@#{local_address}"
      UserSupervisor.add_user(username, count, num_count)
      #IO.inspect GenServer.call({:twitter_engine, server_name}, {:user_register, username, "password", server_name})      
      GenServer.call({:twitter_engine, server_name}, {:user_register, username, "password", server_name})
      simulate_users(count - 1, num_count, server_name, local_address)      
    end
  end

  def user_login(count, num_count, increment, server_name, local_address) do
    if count <= num_count do
      username = :"user#{count}@#{local_address}"
      count = (count + 1)
      case GenServer.call({:twitter_engine, server_name}, {:user_login, username, username}) do
        {:ok, msg} ->
            #IO.inspect msg
            if increment == num_count do
              add_following(username, num_count, increment - 2, server_name, local_address)
            else
              if increment < 1 do
                add_following(username, num_count, 0, server_name, local_address)
              else
                add_following(username, num_count, increment, server_name, local_address)
              end
            end   
                        
        {:error, msg} -> IO.inspect msg
      end
      user_login(count, num_count, increment/2, server_name, local_address)
    end
  end

  def start_sending_tweets(num_users, server_name, local_address, predefined_hashtags, predefined_usernames, predefined_tweets) do
    if num_users > 0 do
        rand = Enum.random(0..4)
        tweet = elem(predefined_tweets, rand) <> elem(predefined_hashtags, rand)  <> elem(predefined_usernames, rand)
        username = :"user#{num_users}@#{local_address}"

        GenServer.cast({:twitter_engine, server_name}, {:send_tweet, username, username, tweet})
        :timer.sleep(2)
        start_sending_tweets(num_users - 1, server_name, local_address, predefined_hashtags, predefined_usernames, predefined_tweets)
    end    
  end

  def start_sending_retweets(num_users, server_name, local_address) do
    if num_users > 0 do  
        username = :"user#{num_users}@#{local_address}"

        GenServer.cast({username, server_name}, {:retweet, server_name})
        :timer.sleep(2)
        start_sending_retweets(num_users - 1, server_name, local_address)
    end
  end  

  def add_following(username, num_count, count, server_name, local_address) do
    if count == 0 do
      nu = Enum.random(1..num_count)
      followed_username = :"user#{nu}@#{local_address}"      
      case GenServer.call({:twitter_engine, server_name}, {:follow, followed_username, username, username}) do
        {:ok, msg} -> 
          #IO.inspect msg
          msg
        {:error, msg} -> IO.inspect msg     
        _ -> IO.inspect ""   
      end      
    else
      if count <= num_count do      
        nu = round(num_count - count)
        if nu == 0 do
          nu = 1
        end
        followed_username = :"user#{nu}@#{local_address}"      
        case GenServer.call({:twitter_engine, server_name}, {:follow, followed_username, username, username}) do
          {:ok, msg} -> 
            #IO.inspect msg
            msg
          {:error, msg} -> IO.inspect msg     
          _ -> 
            IO.inspect nu
            IO.inspect "2"   
        end
        add_following(username, num_count, count+1, server_name, local_address)
      end
    end
  end

  defp find_local_address do
    {:ok, all_ip} = :inet.getif()
    all_ip_tuple = Enum.filter(all_ip, fn(x) ->      
      Enum.join(Tuple.to_list(Enum.at(Tuple.to_list(x), 0))) != "127001"
    end)
    ip_tuple = Enum.at(Tuple.to_list(Enum.at(all_ip_tuple,0)),0)
    :inet.ntoa(ip_tuple)
  end

  def start_distributed(appname) do
    unless Node.alive?() do
      {:ok, _} = Node.start(appname)
    end       
    Node.set_cookie(:cookieName)    
  end

  defp generate_client_name(name, node_name) do    
    hex = :erlang.monotonic_time() |>      
      Integer.to_string(16)
    String.to_atom("#{name}#{hex}@#{node_name}")
  end    
  
end

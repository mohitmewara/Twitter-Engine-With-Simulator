defmodule Twitter.Client.User do
    use GenServer   

    def start_link(name, number, num_count) do 
        GenServer.start_link(__MODULE__, [number, num_count, true, name, %{}], name: name)   
    end

    def handle_cast({:start_user, username, password, num_nodes}, state) do        

        {:noreply, state}
    end

 
    def handle_cast({:logout}, state) do
        
        {:noreply, state}
    end

    def handle_cast({:send_tweet, tweet, local_address, server_name}, state) do        
        number = Enum.at(state, 0)
        num_count = Enum.at(state, 1)
        login = Enum.at(state, 2)
        username = Enum.at(state, 3)       

        if login == true do            
            GenServer.cast({:twitter_engine, server_name}, {:send_tweet, username, username, tweet})
            predefined_hashtags = {"#dos ", "#twitter ", "#fun ", "#project ", "#test "}
            predefined_usernames = {"@user1@#{local_address}", "@user2@#{local_address}", "@user3@#{local_address}", "@user4@#{local_address}", "@user5@#{local_address}"}
            predefined_tweets = {"First tweet ", "Second tweet ", "Third tweet ", "Fourth tweet ", "Fifth tweet "}
            rand = Enum.random(0..4)
            tweet = elem(predefined_tweets, rand) <> elem(predefined_hashtags, rand)  <> elem(predefined_usernames, rand)    
            
            if number <= (num_count/5) do   
                ran = Enum.random(1..4)
                :timer.sleep(ran * 1000)
            else
                ran = Enum.random(8..10)
                :timer.sleep(ran * 1000)
            end
            GenServer.cast({username, server_name}, {:send_tweet, tweet, local_address, server_name})
        end 
        {:noreply, state}
    end

    def handle_cast({:retweet, server_node}, state) do        
        name = Enum.at(state, 3)
        map = Enum.at(state, 4)
        keys = Map.keys(map)
        
        if Enum.at(keys, 0) != nil do
            tweet_list = Map.get(map, Enum.at(keys, 0))
            GenServer.cast({:twitter_engine, server_node}, {:retweet, name, Enum.at(keys, 0), name, Enum.at(tweet_list, 0)})            
        end
        {:noreply, state}
    end    

    def handle_cast({:receive_tweet, username, tweet}, state) do        
        IO.inspect "#{username} tweeted: " <> tweet
        number = Enum.at(state, 0)
        num_count = Enum.at(state, 1)
        login = Enum.at(state, 2)
        name = Enum.at(state, 3)
        map = Enum.at(state, 4)

        if Map.has_key?(map, username) do
            map = Map.put(map, username, [tweet] ++ [Map.get(map, username)])
        else
            map = Map.put(map, username, [tweet])
        end
        state = [number] ++ [num_count] ++ [login] ++[name] ++ [map]
        {:noreply, state}
    end    

    def handle_cast({:receive_retweet, username1, username2, tweet}, state) do        
        IO.inspect "#{username1} re-tweeted #{username2} tweet: " <> tweet
        
        number = Enum.at(state, 0)
        num_count = Enum.at(state, 1)
        login = Enum.at(state, 2)
        name = Enum.at(state, 3)
        map = Enum.at(state, 4)

        if Map.has_key?(map, username1) do
            map = Map.put(map, username1, [tweet] ++ [Map.get(map, username1)])
        else
            map = Map.put(map, username1, [tweet])            
        end
        state = [number] ++ [num_count] ++ [login] ++[name] ++ [map]
        {:noreply, state}
    end

end
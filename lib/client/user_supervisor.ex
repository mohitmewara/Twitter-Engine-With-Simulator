defmodule Twitter.Client.UserSupervisor do
    use Supervisor
    alias Twitter.Client.User

    def start_link do        
        Supervisor.start_link(__MODULE__, [],  name: :user_supervisor)       
    end

    def init(_) do
        children = 
        [            
            worker(User, []),                        
        ]        
        supervise(children, strategy: :simple_one_for_one)        
    end

    def add_user(name, number, num_count) do
        Supervisor.start_child(:user_supervisor, [name, number, num_count])
    end
end

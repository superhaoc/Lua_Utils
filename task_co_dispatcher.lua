
local coroutine_resume = coroutine.resume
local coroutine_yield = coroutine.yield
local coroutine_status = coroutine.status
local TaskUtils = {}
local coroutine_pool = setmetatable({}, { __mode = "kv" })
local function co_create(f)
	local co = table.remove(coroutine_pool)
	if co == nil then
		co = coroutine.create(function(...)
			f(...)
			while true do
				f = nil
				coroutine_pool[#coroutine_pool+1] = co
				f = coroutine_yield "EXIT"
				f(coroutine_yield())
			end
		end)
	else
		coroutine_resume(co, f)
	end
	return co
end

local channelSet = {}
function schedule(co,result,reason)
  if result then
      if reason.res == "Next" then
        schedule(co,coroutine_resume(co.task))
      elseif reason.res == "Time" then
      
      elseif reason.res == "Chan" then
          
   
        if channelSet[#channelSet] ~= reason.value then
        table.insert(channelSet,reason.value)
        end
        
       
      
      end
      
       
      if #channelSet > 0 then
          if channelSet[1].sender ~= nil and channelSet[1].receiver ~= nil then
             local queue = channelSet[1].queue
             
             if #queue > 0 then
                 local msg = queue[1].msg
                 local receiver = channelSet[1].receiver;
                 local sender = channelSet[1].sender
                 table.remove(channelSet,1) 
                 table.remove(queue,1)
                 schedule(receiver,coroutine_resume(receiver,msg))
                 schedule(sender,coroutine_resume(sender))
       
             end
             
          end
      end
  end
end


local tasktable = {}

local newtasktasktable= {}
local newtaskNextRoundTable = {}
TaskUtils.currentCoroutine = nil
local currenttask = nil

local function raw_dispatch_message(prototype, msg, sz, session, source)
    local run = true
    while run do
       
        while #newtasktasktable > 0 do
            
            onetask = table.remove(newtasktasktable,1)
            currenttask = onetask
            ok,ret = coroutine_resume(onetask.task,onetask.msg)
            local status = coroutine.status(onetask.task)
        
 
            if ret ~=  "BLOCK" and status ~= "dead" then
                table.insert(newtaskNextRoundTable,onetask)
            end
        end
        
        for _,v in pairs(newtaskNextRoundTable) do
            table.insert(newtasktasktable,v)
        end
       
        run = #newtaskNextRoundTable > 0
        newtaskNextRoundTable = {}
    
        
    end

    print("done")
    
end


local Channel_t = {}
local Channelmt = { __index = Channel_t} 

Channel_t.Send = function(self,msg_)
   
   --local oldnum = self.num
   --self.num = self.num + 1
   
   if #self.queue <= 0 then
               
        table.insert(self.queue,{msg = msg_, task = currenttask})
         coroutine_yield "BLOCK"
    else
       
         local msgbody = table.remove(self.queue,1)
         
         msgbody.msg = msg_
         msgbody.task.msg = msg_
         table.insert(newtaskNextRoundTable,msgbody.task)
   
   end
   
end

Channel_t.Receive = function(self)
  
   --local oldnum = self.num
  -- self.num = self.num - 1
   
   if #self.queue > 0 then
         local msgbody = table.remove(self.queue,1)
         table.insert(newtaskNextRoundTable,msgbody.task)
         return msgbody.msg
    else
        
        table.insert(self.queue,{msg = nil, task = currenttask})
        return coroutine_yield "BLOCK"
      
        
   end
end

function newChannel()
    
    local channelObj = { queue = {},num = 0}
    setmetatable(channelObj,Channelmt)
    return channelObj

end

local mychannel = newChannel()

function TaskUtils.dispatch_message(...)
	local succ, err = pcall(raw_dispatch_message,...)
end


function TaskUtils.regfunc(func,...)
	local args = table.pack(...)
	local co = co_create(function()
		func(table.unpack(args,1,args.n))
	end)
	table.insert(newtasktasktable, {task=co})
end



TaskUtils.dispatch_message(1)




	
	
function [message_out] = sqs_receive_personal(sqs_url)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Joshua Soderholm, Fugro ROAMES, 2017
%
% WHAT: Recieves sns all messages to sqs_url and deletes messages after they are read
% INPUTS:
% sqs_url: URL for SQS query (String)
% RETURNS:
% message_out: cell array containing messages (cell)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

message_out = {};

while true
	%init
	cmd         = ['export LD_LIBRARY_PATH=/usr/lib; aws sqs receive-message --profile personal --queue-url ',sqs_url,' --max-number-of-messages 10'];
	[sout,eout] = unix(cmd);
	%catch errors and convert out json to struct
	if sout == 0 && ~isempty(eout)
		jstruct = jsondecode(eout);
        %loop through messages
        for i=1:length(jstruct.Messages)
            %extract ith message body
            msg_body   = jstruct.Messages(i).Body;
            msg_struct = jsondecode(msg_body);
            %extract message and receipt-handle
            message        = msg_struct.Message;
            receipt_handle = jstruct.Messages(i).ReceiptHandle;
            %append
            message_out = [message_out,message];
            %delete message in background
            cmd  = ['export LD_LIBRARY_PATH=/usr/lib; aws sqs delete-message --profile personal --queue-url ',sqs_url,' --receipt-handle "',receipt_handle,'" &'];
            [~,~] = unix([cmd,' >> tmp/log.sqs 2>&1 &']);
        end
		%read out message data and receipt-handle
		%append message data to message out
		%delete message using receipt-handle
	elseif sout == 0 && isempty(eout)
		%abort loop, sqs has no additional sns
		break
    end
end







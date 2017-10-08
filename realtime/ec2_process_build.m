%setup compiled directory structure
build_path = 'build/';

addpath('/home/meso/dev/uq-xpol/lib');


if exist(build_path,'file')==7
    delete([build_path,'*'])
else
    mkdir(build_path)
end
addpath(build_path)

display('mcc')
mcc('-m','ec2_process.m','-d',build_path)

%copy global config
etc_path = 'etc';
copyfile('/home/meso/dev/uq-xpol/etc/ec2_process.config',pwd)

display('tar')
tar_fn = [build_path,'ec2_process.tar'];
tar(tar_fn,{'run_ec2_process.sh','ec2_process','ec2_process.config','ec2_process_start','pyart_plot.py','html'})

display('scp')
%ftp primary machine
ec2_ip      = '52.63.3.251';
[sout,eout] = unix(['scp -i /home/meso/keys/joshuas_aws_personal_key.pem ', tar_fn ,' ubuntu@',ec2_ip,':~/ec2_process'])


delete([pwd,'/ec2_process.config'])

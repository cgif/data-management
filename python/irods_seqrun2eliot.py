import os, argparse
from subprocess import call, Popen, PIPE

parser=argparse.ArgumentParser()
parser.add_argument('-b','--base_code_dir',  required=True, help='Base code directory')
parser.add_argument('-d','--base_python_dir',required=True, help='Base python code directory')
parser.add_argument('-s','--ssh_user',       required=True, help='Unix user name for SSH')
parser.add_argument('-u','--irods_user',     required=True, help='IRODS username')
parser.add_argument('-p','--irods_pass',     required=True, help='IRODS password')
parser.add_argument('-i','--input_dir',      required=True, help='Top level file input dir')
parser.add_argument('-t','--slack_token',    required=True, help='Slack bot token')
args=parser.parse_args()

ssh_user=args.ssh_user
input_dir=args.input_dir
irods_user=args.irods_user
irods_pass=args.irods_pass
base_code_dir=args.base_code_dir
base_python_dir=args.base_python_dir
slack_token=args.slack_token

run_list_file=os.path.join(input_dir,'RUN_LIST')
seq_run_dir=os.path.join(input_dir,'illumina')

irods_handler_script='shell/processing/illumina/orwell_script/irods_rundata_handler.sh'
irods_handler_script=os.path.join(base_code_dir,irods_handler_script)
irods_handler_script_basename=os.path.basename(irods_handler_script)

run_list=list()
new_run=list()

with open(run_list_file, 'r') as f:
  for line in f:
    line.strip()
    values=line.split()
    if values[0].startswith('#'): 
      continue                    # skip line if its commented
    run_list.append(values[0])    # keeping only the first column value


for run_id in ((x for x in os.listdir(seq_run_dir) if os.path.isdir(os.path.join(seq_run_dir,x)) if not x.startswith("."))):
  if run_id not in run_list: new_run.append(run_id)

# check current process list
process_list=Popen(['ps','-ef'], stdout=PIPE)
matched_process_pipe=Popen(['grep', irods_handler_script_basename], stdin=process_list.stdout, stdout=PIPE)
filtered_process_pipe=Popen(['grep','-v','grep'],stdin=matched_process_pipe.stdout, stdout=PIPE)
process_list.stdout.close()
matched_process_pipe.stdout.close()

matched_process=filtered_process_pipe.communicate()[0]

# submit job only if new runs found and 
if len(new_run)>0 and len(matched_process)==0:
  for run in new_run:
     rta_file_path=os.path.join(seq_run_dir,run,'RTAComplete.txt')
     if os.path.exists(rta_file_path):
       orwell_run_dir=os.path.join(seq_run_dir,run)
       call([irods_handler_script, orwell_run_dir, irods_user, irods_pass, ssh_user, base_python_dir, 'T', 'T', 'T', slack_token]) # legacy parameters
       print('submitting jobs for {0}'.format(run))


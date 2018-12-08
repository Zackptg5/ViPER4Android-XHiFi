# Do not concatenate classes 
# Only concatenate permissions (the last argument in the statement)
# NOT valid example: audioserver { audioserver_tmpfs mediaserver_tmpfs } file read
#
# Valid entry example: audioserver audioserver_tmpfs file read
# Another valid example: audioserver audioserver_tmpfs file read,write,execute
allow audioserver audioserver_tmpfs file read,write,execute 
allow audioserver system_file file execmod 
allow mediaserver mediaserver_tmpfs file read,write,execute 
allow mediaserver system_file file execmod 
allow audioserver unlabeled file read,write,execute,open,getattr 
allow hal_audio_default hal_audio_default process execmem 
allow hal_audio_default hal_audio_default_tmpfs file execmem 
allow hal_audio_default audio_data_file dir search
allow <SOURCE> system_data_file file open

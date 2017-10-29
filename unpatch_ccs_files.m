function unpatch_ccs_files(ccs_install_root)
%UNPATCH_CCS_FILES Utility to unpatch files in a CCS 7 installation
%   Reverses the action of the patch_ccs_files.m script, by moving the
%   original files from the backup directory to the CCS install directory

    if nargin == 0
        ccs_install_root = uigetdir ('' ,'Select CCS 7 installation root');
        if isequal (ccs_install_root, 0)
            return
        end
    end
    
    if ~exist(fullfile (ccs_install_root, 'ccsv7'), 'dir')
        fprintf ('%s is not a the root directory of a CCS 7 installation\n', ccs_install_root);
        return
    end
    
    % Move the backup files to the CCS installation
    ccs_backup_root = fullfile (ccs_install_root, 'ccsv7_original_files');
    ccs_install_root = fullfile (ccs_install_root, 'ccsv7');
    backup_files = dir (fullfile (ccs_backup_root, '**', '*'));
    num_files = 0;
    for file_index = 1:length(backup_files)
        if ~backup_files(file_index).isdir
            num_files = num_files + 1;
            install_dir = backup_files(file_index).folder(length(ccs_backup_root)+2:end);
            backup_pathname = fullfile (backup_files(file_index).folder, backup_files(file_index).name);
            install_pathname = fullfile (ccs_install_root, install_dir, backup_files(file_index).name);
            [status,msg] = movefile (backup_pathname, install_pathname, 'f');
            if status
                fprintf ('Restored original %s\n', install_pathname);
            else
                fprintf ('Error: restore of %s failed with:\n%s\n', install_pathname, msg);
            end
        end
    end
    
    if num_files == 0
        fprintf ('No backup files to restore for %s\n', ccs_install_root);
        return
    end

    % Remove the backup directory structure which should be empty
    backup_files = dir (fullfile (ccs_backup_root, '**', '*'));
    num_files = 0;
    for file_index = 1:length(backup_files)
        if ~backup_files(file_index).isdir
            num_files = num_files + 1;
        end
    end
    if num_files == 0
        [status,msg] = rmdir (ccs_backup_root, 's');
        if ~status
            fprintf ('Delete of backup directory %s failed with:\n%s\n', ccs_backup_root, msg);
        end
    else
        fprintf ('%s contains %u files, so not removed\', ccs_backup_root, num_files);
    end
end

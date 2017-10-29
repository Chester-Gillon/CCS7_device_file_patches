function patch_ccs_files(ccs_install_root)
%PATCH_CCS_FILES Utility to patch files in a CCS 7 installation
%   Provides a mechanism to patch files in a CCS 7 installation in a way
%   which:
%   - Stores the patched files in a git repo outside of the CCS
%     installation tree.
%   - Stores the unpatched file versions so that only overwrites files in
%     an CCS installation which were the original files at the point a
%     patch was created.

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

    % Set the context containing paths common to all file patched
    context.ccs_install_root = fullfile (ccs_install_root, 'ccsv7');
    context.ccs_backup_root = fullfile (ccs_install_root, 'ccsv7_original_files');
    context.repo_patch_root = fileparts (mfilename ('fullpath'));
    
    % Patch the individual files
    
    % This fixes the problem described in:
    % "CCS/EVMK2H: CCS 7.2.0.00013 Memory Throughput Analysis Hardware
    % Trace Analyser captures from the wrong transaction monitors"
    % https://e2e.ti.com/support/development_tools/code_composer_studio/f/81/t/614498
    patch_ccs_file (context, 'AET_PropertyCP_Tracer_kepler.xml', ...
        'ccs_base/emulation/analysis/xmldb/aet_config');
    
    % Expose a Target Configuration "Interface Type" option for MSP430
    % devices to allow the interface type to be specifed, rather than being
    % detected automatically.
    patch_ccs_file (context, 'msp430_emu.xml', 'ccs_base/common/targetdb/drivers');
end

% Attempt to patch one file in a CCS installation, by replacing the
% original file with a modified file. The original file is moved to a
% backup directory.
function patch_ccs_file (context, filename, ccs_install_dir)
    ccs_install_pathname = fullfile (context.ccs_install_root, ccs_install_dir, filename);
    ccs_backup_pathname = fullfile (context.ccs_backup_root, ccs_install_dir, filename);
    system_type = computer ('arch');
    if ~exist (fullfile (context.repo_patch_root, system_type, 'original', filename), 'file')
        system_type = 'common';
    end
    repo_original_pathname = fullfile (context.repo_patch_root, system_type, 'original', filename);
    repo_modified_pathname = fullfile (context.repo_patch_root, system_type, 'modified', filename);

    % Check required files exist
    if ~exist (repo_original_pathname, 'file')
        fprintf ('Error: %s doesn''t exist in the repo\n', repo_original_pathname);
        return
    elseif ~exist (repo_modified_pathname, 'file')
        fprintf ('Error: %s doesn''t exist in the repo\n', repo_modified_pathname);
    elseif ~exist (ccs_install_pathname, 'file')
        fprintf ('Error: %s doesn''exist in the CCS installation and so can''t be patched\n', ...
            ccs_install_pathname);
        return
    end

    % Determine if to patch the file in the CCS installation
    if compare_file_content (ccs_install_pathname, repo_modified_pathname)
        fprintf ('%s is already patched\n', ccs_install_pathname);
        return
    elseif compare_file_content (ccs_install_pathname, repo_original_pathname)
        % Backup the orignal file from the CCS installation
        backup_dir = fileparts (ccs_backup_pathname);
        [status,msg] = mkdir (backup_dir);
        if ~status
            fprintf ('Error: failed to create backup directory %s failed with:\n%s\n', ...
                backup_dir, msg);
            return
        end
        [status,msg] = movefile (ccs_install_pathname, ccs_backup_pathname);
        if ~status
            fprintf ('Error: backup of %s failed with:\n%s\n', ...
                ccs_install_pathname, msg);
            return
        end
        
        % Copy the modified file into the CCS installation
        [status,msg] = copyfile (repo_modified_pathname, ccs_install_pathname, 'f');
        if ~status
            fprintf ('Error: modification of %s failed with:\n%s\n', ...
                ccs_install_pathname, msg);
            return
        end
        
        fprintf ('Patched %s\n', ccs_install_pathname);
    else
        fprintf ('%s doesn''t match the original or modified file and so not changed\n', ...
            ccs_install_pathname);
        return
    end
end

% Determine if two files contain the same content
function is_equal = compare_file_content (pathname_a, pathname_b)
    file_a = javaObject ('java.io.File', pathname_a);
    file_b = javaObject ('java.io.File', pathname_b);
    is_equal = javaMethod ('contentEquals', 'org.apache.commons.io.FileUtils', ...
        file_a, file_b);
end
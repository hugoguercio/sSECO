USE [msdb]
GO

/****** Object:  Job [Restore Sample]    32 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory [[Uncategorized (Local)]]    32 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'[Uncategorized (Local)]' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'[Uncategorized (Local)]'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'Restore Sample', 
		@enabled=1, 
		@notify_level_eventlog=0, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'No description available.', 
		@category_name=N'[Uncategorized (Local)]', 
		@owner_login_name=N'DESKTOP-NAM48FU\Qih', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Ensure tables are empty]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Ensure tables are empty', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'EXEC sys.sp_MSforeachtable ''DELETE FROM ?''', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Load Targeted Users]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Load Targeted Users', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'DECLARE @sample_id AS NVARCHAR(3) = (SELECT param_value FROM GHT_sample_helper.dbo.t_job_parameter WHERE param_name =''sample'')
DECLARE @SQL AS NVARCHAR(max) =N''SET IDENTITY_INSERT dbo.users ON;
INSERT INTO dbo.users
(
	id,
    login,
    company,
    created_at,
    type,
    fake,
    deleted,
    long,
    lat,
    country_code,
    state,
    city,
    location
)
SELECT *
FROM GHTorrent.dbo.users
WHERE [login] IN (
                     SELECT user_login
                     FROM GHT_sample_helper.dbo.t_user
                     WHERE [sample] = ''+@sample_id+''
                 );
SET IDENTITY_INSERT dbo.users OFF;''


EXEC sys.sp_executesql @SQL
', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore projects]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore projects', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.projects ON;
INSERT INTO dbo.projects
(
	id,
    url,
    owner_id,
    name,
    description,
    language,
    created_at,
    forked_from,
    deleted,
    updated_at
)
SELECT * FROM GHTorrent.dbo.projects WHERE owner_id IN (SELECT id FROM dbo.users)
SET IDENTITY_INSERT dbo.projects OFF;', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore Fork Projects]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore Fork Projects', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.projects ON;
INSERT INTO dbo.projects
(
	id,
    url,
    owner_id,
    name,
    description,
    language,
    created_at,
    forked_from,
    deleted,
    updated_at
)
SELECT * FROM GHTorrent.dbo.projects WHERE forked_from IN (SELECT id FROM dbo.projects)
SET IDENTITY_INSERT dbo.projects OFF;', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore watchers]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore watchers', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.watchers
(
    repo_id,
    user_id,
    created_at
)
SELECT * FROM GHTorrent.dbo.watchers w WHERE EXISTS (SELECT * FROM dbo.projects WHERE id = w.repo_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore project languages]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore project languages', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.project_languages
(
    project_id,
    language,
    bytes,
    created_at
)
SELECT * FROM GHTorrent.dbo.project_languages rl WHERE EXISTS (SELECT * FROM dbo.projects WHERE id = rl.project_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore repo labels]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore repo labels', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.repo_labels ON;
INSERT INTO dbo.repo_labels
(
	id,
    repo_id,
    name
)
SELECT * FROM GHTorrent.dbo.repo_labels rl WHERE EXISTS (SELECT id FROM dbo.projects WHERE dbo.projects.id = rl.repo_id)
SET IDENTITY_INSERT dbo.repo_labels OFF;', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore issues]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore issues', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.issues ON;
INSERT INTO dbo.issues
(
	id,
    repo_id,
    reporter_id,
    assignee_id,
    pull_request,
    pull_request_id,
    created_at,
    issue_id
)
SELECT * FROM GHTorrent.dbo.issues i WHERE EXISTS (SELECT id FROM dbo.projects aux WHERE aux.id = i.repo_id)
SET IDENTITY_INSERT dbo.issues OFF;


', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore issue labels]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore issue labels', 
		@step_id=9, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.issue_labels
(
    label_id,
    issue_id
)
SELECT * FROM GHTorrent.dbo.issue_labels il WHERE EXISTS (SELECT * FROM dbo.repo_labels WHERE id = il.label_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore issue events]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore issue events', 
		@step_id=10, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.issue_events
(
    event_id,
    issue_id,
    actor_id,
    action,
    action_specific,
    created_at
)
SELECT * FROM GHTorrent.dbo.issue_events i WHERE EXISTS (SELECT id FROM dbo.issues aux WHERE aux.id = i.issue_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore issue comments]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore issue comments', 
		@step_id=11, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.issue_comments
(
    issue_id,
    user_id,
    comment_id,
    created_at
)
SELECT * FROM GHTorrent.dbo.issue_comments i WHERE EXISTS (SELECT id FROM dbo.issues aux WHERE aux.id = i.issue_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore project commits]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore project commits', 
		@step_id=12, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.project_commits
(
    project_id,
    commit_id
)
SELECT * FROM GHTorrent.dbo.project_commits pc WHERE EXISTS (SELECT * FROM dbo.projects aux WHERE aux.id = pc.project_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore commits]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore commits', 
		@step_id=13, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.commits ON;
INSERT INTO dbo.commits
(
	id,
    sha,
    author_id,
    committer_id,
    project_id,
    created_at
)
SELECT * FROM GHTorrent.dbo.commits c WHERE EXISTS (SELECT * FROM dbo.project_commits aux WHERE aux.commit_id = c.id)
SET IDENTITY_INSERT dbo.commits OFF;', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore commit comments]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore commit comments', 
		@step_id=14, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.commit_comments ON;
INSERT INTO dbo.commit_comments
(
	id,
    commit_id,
    user_id,
    body,
    line,
    position,
    comment_id,
    created_at
)
SELECT * FROM GHTorrent.dbo.commit_comments c WHERE EXISTS (SELECT * FROM dbo.commits aux WHERE aux.id = c.commit_id)
SET IDENTITY_INSERT dbo.commit_comments OFF;
', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore pull requests]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore pull requests', 
		@step_id=15, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.pull_requests ON;
INSERT INTO dbo.pull_requests
(
	id,
    head_repo_id,
    base_repo_id,
    head_commit_id,
    base_commit_id,
    pullreq_id,
    intra_branch
)
SELECT * FROM GHTorrent.dbo.pull_requests pc WHERE EXISTS (SELECT * FROM dbo.projects aux WHERE aux.id = pc.head_repo_id)
SET IDENTITY_INSERT dbo.pull_requests OFF;
', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore pull request commits]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore pull request commits', 
		@step_id=16, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.pull_request_commits
(
    pull_request_id,
    commit_id
)
SELECT * FROM GHTorrent.dbo.pull_request_commits prc WHERE EXISTS (SELECT * FROM dbo.pull_requests aux WHERE aux.id = prc.pull_request_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore pull request history]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore pull request history', 
		@step_id=17, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'SET IDENTITY_INSERT dbo.pull_request_history ON;
INSERT INTO dbo.pull_request_history
(
	id,
    pull_request_id,
    created_at,
    action,
    actor_id
)
SELECT * FROM GHTorrent.dbo.pull_request_history prh WHERE EXISTS (SELECT * FROM dbo.pull_requests aux WHERE aux.id = prh.pull_request_id)
SET IDENTITY_INSERT dbo.pull_request_history OFF;
', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore pull request comments]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore pull request comments', 
		@step_id=18, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.pull_request_comments
(
    pull_request_id,
    user_id,
    comment_id,
    position,
    body,
    commit_id,
    created_at
)
SELECT * FROM GHTorrent.dbo.pull_request_comments prc WHERE EXISTS (SELECT * FROM dbo.pull_requests aux WHERE aux.id = prc.pull_request_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore users]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore users', 
		@step_id=19, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'CREATE TABLE #users_to_restore (userid INT)

INSERT INTO #users_to_restore
SELECT DISTINCT reporter_id FROM dbo.issues
INSERT INTO #users_to_restore
SELECT DISTINCT assignee_id FROM dbo.issues
INSERT INTO #users_to_restore
SELECT DISTINCT [user_id] FROM dbo.issue_comments
INSERT INTO #users_to_restore
SELECT DISTINCT actor_id FROM dbo.issue_events
INSERT INTO #users_to_restore
SELECT DISTINCT [user_id] FROM dbo.watchers
INSERT INTO #users_to_restore
SELECT DISTINCT actor_id FROM dbo.pull_request_history
INSERT INTO #users_to_restore
SELECT DISTINCT [user_id] FROM dbo.pull_request_comments
INSERT INTO #users_to_restore
SELECT DISTINCT [user_id] FROM dbo.commit_comments
INSERT INTO #users_to_restore
SELECT DISTINCT author_id FROM dbo.commits


CREATE TABLE #users (userid INT)
INSERT INTO #users
SELECT DISTINCT userid FROM #users_to_restore
DROP TABLE #users_to_restore

DELETE FROM #users WHERE userid IN (SELECT id FROM dbo.users)

SET IDENTITY_INSERT dbo.users ON;
INSERT INTO dbo.users
(
	id,
    login,
    company,
    created_at,
    type,
    fake,
    deleted,
    long,
    lat,
    country_code,
    state,
    city,
    location
)
SELECT * FROM GHTorrent.dbo.users u WHERE EXISTS (SELECT * FROM #users aux WHERE aux.userid = u.id)
SET IDENTITY_INSERT dbo.users OFF;
DROP TABLE #users', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Restore followers]    33 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Restore followers', 
		@step_id=20, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'INSERT INTO dbo.followers
(
    user_id,
    follower_id,
    created_at
)
SELECT * FROM GHTorrent.dbo.followers f WHERE EXISTS (SELECT * FROM dbo.users WHERE id = f.user_id)', 
		@database_name=N'GHT_Eclipse', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:
GO



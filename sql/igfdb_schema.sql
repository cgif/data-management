DROP TABLE igf_system;
DROP TABLE igf_workflow;
DROP TABLE igf_project;
DROP TABLE igf_job;
DROP TABLE igf_script_type;
DROP TABLE igf_run;
DROP TABLE igf_run_to_job;

CREATE TABLE igf_system (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	system_name VARCHAR(10) UNIQUE NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE igf_workflow (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	workflow_name VARCHAR(10) UNIQUE NOT NULL,
	analysis_type_id INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE igf_project (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	project_tag VARCHAR(15) UNIQUE NOT NULL,
	project_name TEXT,	
	PRIMARY KEY (id)
);

CREATE TABLE igf_job (
	id INT(10) UNSIGNED NOT NULL,
	job_name VARCHAR(15) NOT NULL,
	system_id INT(1) UNSIGNED NOT NULL,
	exit_status INT(4) UNSIGNED NOT NULL,
	cpu_percent INT(5) UNSIGNED NOT NULL,
	cput TIME NOT NULL,
	mem_kb INT(10) UNSIGNED NOT NULL,
	ncpus INT(4) UNSIGNED NOT NULL,
	vmem_kb INT(10) UNSIGNED NOT NULL,
	walltime TIME NOT NULL,
	start_time DATETIME NOT NULL,
	end_time DATETIME NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (script_id) REFERENCES igf_script_type(id),
	FOREIGN KEY (system_id) REFERENCES igf_system(id)
);

CREATE TABLE igf_script (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	script_name VARCHAR(15) UNIQUE NOT NULL,
	workflow_id INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (workflow_id) REFERENCES igf_workflow(id)
);

CREATE TABLE igf_run (
	id INT(10) UNSIGNED UNIQUE NOT NULL AUTO_INCREMENT,
	project_id INT(10) NOT NULL,
	date_time DATETIME NOT NULL,	
	PRIMARY KEY (id),
	FOREIGN KEY (project_id) REFERENCES igf_project(id)
);

CREATE TABLE igf_run_to_job (
	id INT(10) UNSIGNED UNIQUE NOT NULL AUTO_INCREMENT,
	run_id INT(10) NOT NULL,
	job_id INT(10) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (run_id) REFERENCES igf_run(id),
	FOREIGN KEY (job_id) REFERENCES igf_job(id)
);

CREATE TABLE igf_resource (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	resource_name VARCHAR(50) UNIQUE NOT NULL,
	resource_url VARCHAR(100) UNIQUE NOT NULL,
	size_kb BIGINT NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE igf_resource_usage (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	resource_id INT(10) UNSIGNED NOT NULL,
	used_kb BIGINT UNIQUE NOT NULL,
	date_time DATETIME NOT NULL,	
	PRIMARY KEY (id),
	FOREIGN KEY (resource_id) REFERENCES igf_resource(id)
);


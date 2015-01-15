DROP TABLE data_category;
DROP TABLE project;
DROP TABLE run;
DROP TABLE run_to_job;
DROP TABLE script;
DROP TABLE storage_resource;
DROP TABLE storage_resource_usage;
DROP TABLE storage_resource_usage_project;
DROP TABLE system;
DROP TABLE workflow;
DROP TABLE job;

CREATE TABLE system (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	system_name VARCHAR(10) UNIQUE NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE storage_resource (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	resource_name VARCHAR(50) UNIQUE NOT NULL,
	resource_url VARCHAR(100) UNIQUE NOT NULL,
	system_id INT(10) UNSIGNED NOT NULL,
	size_kb BIGINT NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (system_id) REFERENCES system(id)
);

CREATE TABLE storage_resource_usage (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	resource_id INT(10) UNSIGNED NOT NULL,
	used_kb BIGINT UNIQUE NOT NULL,
	date_time DATETIME NOT NULL,	
	PRIMARY KEY (id),
	FOREIGN KEY (resource_id) REFERENCES resource(id)
);

CREATE TABLE storage_resource_usage_project (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	storage_resource_usage_id INT(10) UNSIGNED NOT NULL,
	project_id INT(10) UNSIGNED NOT NULL,
	data_category INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (storage_resource_usage_id) REFERENCES storage_resource_usage(id)
);

CREATE TABLE data_category (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	name VARCHAR(20) NOT NULL,
	directory_name VARCHAR(20) NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE workflow (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	workflow_name VARCHAR(10) UNIQUE NOT NULL,
	analysis_type_id INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (id)
);

CREATE TABLE project (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	igf_project_id VARCHAR(10) UNIQUE NOT NULL,
	project_tag VARCHAR(50) UNIQUE NOT NULL,
	project_name TEXT,
	contact_email VARCHAR(50),
	project_password VARCHAR(10),
	PRIMARY KEY (id)
);

CREATE TABLE job (
	id INT(10) UNSIGNED NOT NULL,
	job_name VARCHAR(15) NOT NULL,
	system_id INT(1) UNSIGNED NOT NULL,
	script_id INT(1) UNSIGNED NOT NULL,
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
	FOREIGN KEY (script_id) REFERENCES script_type(id),
	FOREIGN KEY (system_id) REFERENCES system(id)
);

CREATE TABLE script (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	script_name VARCHAR(15) UNIQUE NOT NULL,
	workflow_id INT(10) UNSIGNED NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (workflow_id) REFERENCES workflow(id)
);

CREATE TABLE run (
	id INT(10) UNSIGNED UNIQUE NOT NULL AUTO_INCREMENT,
	project_id INT(10) NOT NULL,
	date_time DATETIME NOT NULL,	
	PRIMARY KEY (id),
	FOREIGN KEY (project_id) REFERENCES project(id)
);

CREATE TABLE run_to_job (
	id INT(10) UNSIGNED UNIQUE NOT NULL AUTO_INCREMENT,
	run_id INT(10) NOT NULL,
	job_id INT(10) NOT NULL,
	PRIMARY KEY (id),
	FOREIGN KEY (run_id) REFERENCES run(id),
	FOREIGN KEY (job_id) REFERENCES job(id)
);



-- MYSQL 中的 IN 和OUT, IN是传入，OUT 是传出，默认是IN
DELIMITER //
CREATE PROCEDURE USP_GETEMPLOYEENAME(IN ID INT, OUT NAME VARCHAR(20))
BEGIN
SELECT EMP_NAME INTO NAME FROM EMPLOYEE WHERE EMP_ID = ID;
END//
DELIMITER ;
CALL USP_GETEMPLOYEENAME(103, @NAME);
SELECT @NAME;

-- 找出第N名次的记录，并且存储在临时的表中
SET NAMES UTF8;
DROP PROCEDURE IF EXISTS `FIND_LAST_GRADE`;
DELIMITER $$
CREATE PROCEDURE `FIND_LAST_GRADE`(CAREER_ID VARCHAR(20),LIMIT_NUM INT)
	BEGIN
		DECLARE LIMIT_NUM_BEFORE INT;
		SET LIMIT_NUM_BEFORE = LIMIT_NUM*2-2;
	    INSERT INTO 临时表 SELECT 岗位代码,成绩 FROM 排名表 WHERE 岗位代码=CAREER_ID GROUP BY 成绩 ORDER BY 成绩 DESC LIMIT LIMIT_NUM_BEFORE,1;
	END$$
DELIMITER ;
-- 对SELECT的结果 循环操作
DROP PROCEDURE IF EXISTS `FIND_PROPER_CANDIDATE`;
DELIMITER $$
	CREATE PROCEDURE `FIND_PROPER_CANDIDATE`()
		BEGIN
			DECLARE _A1 VARCHAR(20);
			DECLARE _A2 VARCHAR(100);
			DECLARE _A3 INT;
			DECLARE I INT DEFAULT 0;
			DECLARE DONE INT DEFAULT FALSE;
			DECLARE CAREER_INFO CURSOR FOR SELECT 岗位代码,单位全称,岗位人数 FROM 岗位表;
			DECLARE CONTINUE HANDLER FOR NOT FOUND SET DONE = TRUE;
			OPEN CAREER_INFO;
			MY_LOOP:LOOP
				FETCH CAREER_INFO INTO _A1,_A2,_A3;
				IF DONE THEN
			      LEAVE MY_LOOP;
			    END IF;
			    SET I=I+1;
				CALL FIND_LAST_GRADE(_A1,_A3);
			END LOOP;
			CLOSE CAREER_INFO;
		END$$
DELIMITER ;
-- 建立临时表，清空结果表
DROP PROCEDURE IF EXISTS `FIND_RESULT_PRO`;
DELIMITER $$
	CREATE PROCEDURE `FIND_RESULT_PRO`()
		BEGIN
			TRUNCATE TABLE 结果表;
			DROP TABLE IF EXISTS `临时表`;
			CREATE  TABLE `临时表` (
			  `岗位代码` VARCHAR(30) NOT NULL,
			  `成绩` FLOAT(20,1) NOT NULL
			) ENGINE=INNODB DEFAULT CHARSET=UTF8;
			CALL FIND_PROPER_CANDIDATE();
			INSERT INTO 结果表 SELECT A.准考证号,B.岗位代码,A.人数,A.成绩,A.笔试排名,A.分数线 FROM 排名表 AS A RIGHT JOIN 临时表 AS B ON A.岗位代码=B.岗位代码 AND A.成绩>=B.成绩;
			-- DROP TABLE 临时表;
		END$$
DELIMITER ;
CALL FIND_RESULT_PRO();

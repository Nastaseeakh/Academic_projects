/* Задание 2
    2.1 Усердные ученики

Образовательные курсы состоят из различных уроков, каждый из которых состоит из нескольких маленьких заданий. Каждое такое маленькое задание называется "горошиной".
Назовём очень усердным учеником того пользователя, который хотя бы раз за текущий месяц правильно решил 20 горошин за час

Дана таблица peas:
Название атрибута	Тип атрибута 	Смысловое значение
st_id	int	ID ученика
timest	timestamp	Время решения карточки
correct	bool	Правильно ли решена горошина?
subject	text	Дисциплина, в которой находится горошина

Необходимо написать оптимальный запрос, который даст информацию о количестве очень усердных студентов за март 2020 года.
NB! Под усердным студентом мы понимаем студента, который правильно решил 20 задач за текущий месяц.
*/
    
-- 2.1.
SELECT COUNT(*) AS "Усердных учеников за март 2020 г."
FROM
    (--сводная таблица студент - кол-во правильно решенных горошин:
    SELECT st_id, SUM(correct) AS correct_peas
    FROM default.peas
    WHERE
        toStartOfMonth(timest) = '2020-03-01' -- в марте 2020
    GROUP BY st_id
    HAVING correct_peas >= 20) -- выбираем правильно решивших не менее 20 горошин


/*2.2 Оптимизация воронки

Образовательная платформа предлагает пройти студентам курсы по модели trial: студент может решить бесплатно лишь 30 горошин в день. Для неограниченного количества заданий в определенной дисциплине студенту необходимо приобрести полный доступ. Команда провела эксперимент, где был протестирован новый экран оплаты.

Дана таблицы: peas (см. выше), studs:
Название атрибута	Тип атрибута 	Смысловое значение
st_id	int 	ID ученика
test_grp	text 	Метка ученика в данном эксперименте

и checks:
Название атрибута	Тип атрибута 	Смысловое значение
st_id	int 	ID ученика
sale_time	timestamp	Время покупки
money	int	Цена, по которой приобрели данный курс
subject	text 	Дисциплина, на которую приобрели полный доступ

Необходимо в одном запросе выгрузить следующую информацию о группах пользователей:
    ARPU 
    ARPAU 
    CR в покупку 
    СR активного пользователя в покупку 
    CR пользователя из активности по математике (subject = ’math’) в покупку курса по математике.*/
    
-- 2.2.
WITH user_data AS -- сводная таблица по пользователям
    (SELECT DISTINCT studs.st_id AS st_id,          -- уникальные студенты
            studs.test_grp As group,                -- принадлежность к группе
            act.subjects_studied AS subjects_studied,  -- изученные курсы
            checksagg.revenue AS revenue,              -- сумма оплат    
            checksagg.subjects_purchased AS subjects_purchased  -- оплаченные курсы
    FROM default.studs AS studs  -- все студенты
        LEFT JOIN (SELECT st_id, groupUniqArray(subject) AS subjects_studied -- группируем изучаемые курсы по студентам
                    FROM default.peas
                    GROUP BY st_id) AS act
            ON act.st_id == studs.st_id
        LEFT JOIN (SELECT st_id, SUM(money) AS revenue, groupUniqArray(subject) AS subjects_purchased --группируем купленные курсы по студентам
                    FROM default.final_project_check
                    GROUP BY st_id) AS checksagg
            ON studs.st_id == checksagg.st_id)

SELECT group, 
        SUM(revenue) / COUNT(st_id) AS ARPU,
        SUM(revenue) / SUM(notEmpty(subjects_studied)) AS ARPAU,
        countIf(notEmpty(subjects_purchased)) / COUNT(st_id) AS CR, -- считаем долю непустых массивов с купленными курсами в общем числе
        countIf(notEmpty(subjects_purchased)) / SUM(notEmpty(subjects_studied)) AS CR_active, -- считаем долю непустых массивов с купленными курсами в числе непустых массивов изучаемых курсов
        countIf(like(toString(subjects_purchased), '%Math%') AND like(toString(subjects_studied), '%Math%')) / countIf(like(toString(subjects_studied), '%Math%')) AS CR_math  -- доля изучающих и купивших курсы по математике в общем числе изучающих ее
FROM user_data
GROUP BY group
ORDER BY group
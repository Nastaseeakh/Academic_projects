""" Задание 2
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

2.2 Оптимизация воронки

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
    CR пользователя из активности по математике (subject = ’math’) в покупку курса по математике."""
    
-- 2.1.
SELECT COUNT(*) AS "Усердных учеников за март 2020 г."
FROM
    SELECT st_id, SUM(correct) AS correct_peas
    FROM peas
    WHERE
        toStartOfMonth(timest) = '2020-03-01'
    GROUP BY st_id
    HAVING correct_peas >= 20)

-- 2.2.
WITH user_data AS -- сводная таблица по пользователям с указанием группы, изучаемых и оплаченных курсов
    (SELECT studs.st_id AS st_id,
            studs.test_grp As group,
            act.subjects_studied AS subjects_studied,
            checksagg.revenue AS revenue,
            checksagg.subjects_purchased AS subjects_purchased
    FROM studs
        LEFT JOIN (SELECT st_id, groupUniqArray(subject) AS subjects_studied
                    FROM peas
                    GROUP BY st_id) AS act
            ON act.st_id == studs.st_id
        LEFT JOIN (SELECT st_id, SUM(money) AS revenue, groupUniqArray(subject) AS subjects_purchased
                    FROM checks
                    GROUP BY st_id) AS checksagg
            ON studs.st_id == checksagg.st_id)

SELECT group, 
        ROUND(SUM(revenue) / COUNT(st_id), 2) AS ARPU,
        ROUND(SUM(revenue) / SUM(notEmpty(subjects_studied)), 2) AS ARPAU,
        ROUND(SUM(notEmpty(subjects_purchased)) / COUNT(st_id) * 100, 2) AS CR_percent,
        ROUND(SUM(notEmpty(subjects_purchased)) / SUM(notEmpty(subjects_studied)) * 100, 2) AS CR_active_percent,
        ROUND(SUM(like(toString(subjects_purchased), '%math%')) / SUM(like(toString(subjects_studied), '%math%')) * 100, 2) AS CR_math_percent
FROM user_data
GROUP BY group
ORDER BY group
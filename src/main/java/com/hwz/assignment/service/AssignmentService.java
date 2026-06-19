package com.hwz.assignment.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.hwz.assignment.dto.AssignmentDtos;
import com.hwz.assignment.entity.Assignment;
import com.hwz.assignment.entity.AssignmentMaterial;
import com.hwz.assignment.entity.AssignmentQuestion;
import com.hwz.assignment.entity.AssignmentSubmission;
import com.hwz.assignment.entity.AssignmentSubmissionFile;
import com.hwz.assignment.mapper.AssignmentMapper;
import com.hwz.assignment.mapper.AssignmentMaterialMapper;
import com.hwz.assignment.mapper.AssignmentQuestionMapper;
import com.hwz.assignment.mapper.AssignmentSubmissionFileMapper;
import com.hwz.assignment.mapper.AssignmentSubmissionMapper;
import com.hwz.common.PageResponse;
import com.hwz.common.entity.User;
import com.hwz.common.mapper.UserMapper;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.server.ResponseStatusException;

import java.math.BigDecimal;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;
import java.util.zip.ZipEntry;
import java.util.zip.ZipOutputStream;
import java.nio.charset.StandardCharsets;

@Service
public class AssignmentService {

    public static final String STATUS_DRAFT = "DRAFT";
    public static final String STATUS_PUBLISHED = "PUBLISHED";
    public static final String STATUS_ARCHIVED = "ARCHIVED";
    public static final String SUBMISSION_DRAFT = "DRAFT";
    public static final String SUBMISSION_SUBMITTED = "SUBMITTED";
    public static final String SUBMISSION_LATE = "LATE";
    public static final String SUBMISSION_GRADED = "GRADED";
    public static final String SUBMISSION_RETURNED = "RETURNED";
    private static final String STATUS_NO_MATCH = "__NO_MATCH__";

    private final AssignmentMapper assignmentMapper;
    private final AssignmentQuestionMapper questionMapper;
    private final AssignmentMaterialMapper materialMapper;
    private final AssignmentSubmissionMapper submissionMapper;
    private final AssignmentSubmissionFileMapper fileMapper;
    private final UserMapper userMapper;
    private final AssignmentFileStorageService fileStorageService;
    private final AssignmentMaterialStorageService materialStorageService;

    public AssignmentService(AssignmentMapper assignmentMapper,
                             AssignmentQuestionMapper questionMapper,
                             AssignmentMaterialMapper materialMapper,
                             AssignmentSubmissionMapper submissionMapper,
                             AssignmentSubmissionFileMapper fileMapper,
                             UserMapper userMapper,
                             AssignmentFileStorageService fileStorageService,
                             AssignmentMaterialStorageService materialStorageService) {
        this.assignmentMapper = assignmentMapper;
        this.questionMapper = questionMapper;
        this.materialMapper = materialMapper;
        this.submissionMapper = submissionMapper;
        this.fileMapper = fileMapper;
        this.userMapper = userMapper;
        this.fileStorageService = fileStorageService;
        this.materialStorageService = materialStorageService;
    }

    public PageResponse<AssignmentDtos.AssignmentSummary> pageAdmin(String keyword, String status, long page, long pageSize) {
        long total = assignmentMapper.selectCount(assignmentQuery(keyword, status, false));
        Page<Assignment> result = assignmentMapper.selectPage(new Page<>(page, pageSize), assignmentQuery(keyword, status, false));
        List<AssignmentDtos.AssignmentSummary> records = result.getRecords().stream()
                .map(this::toAdminSummary)
                .collect(Collectors.toList());
        return PageResponse.of(records, total, page, pageSize);
    }

    public Map<String, Long> adminStats(String keyword, String status) {
        Map<String, Long> stats = new LinkedHashMap<>();
        List<Long> assignmentIds = assignmentMapper.selectList(assignmentQuery(keyword, status, false))
                .stream()
                .map(Assignment::getAssignmentId)
                .collect(Collectors.toList());

        stats.put("total", assignmentMapper.selectCount(assignmentQuery(keyword, status, false)));
        stats.put("draft", assignmentMapper.selectCount(assignmentQuery(keyword, restrictStatus(status, STATUS_DRAFT), false)));
        stats.put("published", assignmentMapper.selectCount(assignmentQuery(keyword, restrictStatus(status, STATUS_PUBLISHED), false)));
        stats.put("archived", assignmentMapper.selectCount(assignmentQuery(keyword, restrictStatus(status, STATUS_ARCHIVED), false)));
        stats.put("submissions", countSubmissions(assignmentIds, null));
        stats.put("graded", countSubmissions(assignmentIds, SUBMISSION_GRADED));
        return stats;
    }

    public PageResponse<AssignmentDtos.AssignmentSummary> pageStudent(Long userId, String keyword, long page, long pageSize) {
        long total = assignmentMapper.selectCount(assignmentQuery(keyword, STATUS_PUBLISHED, true));
        Page<Assignment> result = assignmentMapper.selectPage(new Page<>(page, pageSize), assignmentQuery(keyword, STATUS_PUBLISHED, true));
        List<AssignmentDtos.AssignmentSummary> records = result.getRecords().stream()
                .map(item -> {
                    AssignmentDtos.AssignmentSummary summary = toSummary(item);
                    summary.setMySubmission(toSubmissionSummary(findSubmission(item.getAssignmentId(), userId)));
                    return summary;
                })
                .collect(Collectors.toList());
        return PageResponse.of(records, total, page, pageSize);
    }

    public Map<String, Long> studentStats(Long userId, String keyword) {
        Map<String, Long> stats = new LinkedHashMap<>();
        List<Long> assignmentIds = assignmentMapper.selectList(assignmentQuery(keyword, STATUS_PUBLISHED, true))
                .stream()
                .map(Assignment::getAssignmentId)
                .collect(Collectors.toList());
        long total = assignmentIds.size();

        if (assignmentIds.isEmpty()) {
            stats.put("total", 0L);
            stats.put("submitted", 0L);
            stats.put("graded", 0L);
            stats.put("pending", 0L);
            return stats;
        }

        List<AssignmentSubmission> submissions = submissionMapper.selectList(new LambdaQueryWrapper<AssignmentSubmission>()
                .in(AssignmentSubmission::getAssignmentId, assignmentIds)
                .eq(AssignmentSubmission::getStudentId, userId));
        long submitted = submissions.stream()
                .filter(item -> SUBMISSION_SUBMITTED.equals(item.getStatus())
                        || SUBMISSION_LATE.equals(item.getStatus())
                        || SUBMISSION_GRADED.equals(item.getStatus()))
                .count();
        long graded = submissions.stream()
                .filter(item -> SUBMISSION_GRADED.equals(item.getStatus()))
                .count();

        stats.put("total", total);
        stats.put("submitted", submitted);
        stats.put("graded", graded);
        stats.put("pending", Math.max(total - submitted, 0));
        return stats;
    }

    public AssignmentDtos.AssignmentDetail getAdminDetail(Long assignmentId) {
        return toDetail(getAssignmentOrThrow(assignmentId), null);
    }

    public AssignmentDtos.AssignmentDetail getStudentDetail(Long assignmentId, Long userId) {
        Assignment assignment = getAssignmentOrThrow(assignmentId);
        if (!STATUS_PUBLISHED.equalsIgnoreCase(assignment.getStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "考核不存在或尚未发布");
        }
        return toDetail(assignment, userId);
    }

    @Transactional
    public AssignmentDtos.AssignmentDetail create(AssignmentDtos.AssignmentSaveRequest request, User operator) {
        validateSaveRequest(request);
        LocalDateTime now = LocalDateTime.now();
        Assignment assignment = Assignment.builder()
                .title(request.getTitle().trim())
                .description(request.getDescription())
                .category(request.getCategory())
                .deadline(request.getDeadline())
                .totalScore(defaultScore(request.getTotalScore()))
                .status(STATUS_DRAFT)
                .createdBy(operator.getId())
                .createdAt(now)
                .updatedAt(now)
                .build();
        assignmentMapper.insert(assignment);
        replaceQuestions(assignment.getAssignmentId(), request.getQuestions());
        return getAdminDetail(assignment.getAssignmentId());
    }

    @Transactional
    public AssignmentDtos.AssignmentDetail update(Long assignmentId, AssignmentDtos.AssignmentSaveRequest request) {
        validateSaveRequest(request);
        Assignment assignment = getAssignmentOrThrow(assignmentId);
        assignment.setTitle(request.getTitle().trim());
        assignment.setDescription(request.getDescription());
        assignment.setCategory(request.getCategory());
        assignment.setDeadline(request.getDeadline());
        assignment.setTotalScore(defaultScore(request.getTotalScore()));
        assignment.setUpdatedAt(LocalDateTime.now());
        assignmentMapper.updateById(assignment);
        replaceQuestions(assignmentId, request.getQuestions());
        return getAdminDetail(assignmentId);
    }

    public AssignmentDtos.AssignmentDetail updateStatus(Long assignmentId, String status) {
        Assignment assignment = getAssignmentOrThrow(assignmentId);
        String normalized = normalizeAssignmentStatus(status);
        assignment.setStatus(normalized);
        assignment.setUpdatedAt(LocalDateTime.now());
        assignmentMapper.updateById(assignment);
        return getAdminDetail(assignmentId);
    }

    @Transactional
    public AssignmentDtos.MaterialDetail uploadMaterial(Long assignmentId, String materialType, String title, MultipartFile file) {
        getAssignmentOrThrow(assignmentId);
        long materialCount = materialMapper.selectCount(new LambdaQueryWrapper<AssignmentMaterial>()
                .eq(AssignmentMaterial::getAssignmentId, assignmentId));
        int sortOrder = (int) Math.min(materialCount + 1, Integer.MAX_VALUE);
        AssignmentMaterial material = materialStorageService.store(assignmentId, materialType, title, sortOrder, file);
        materialMapper.insert(material);
        return toMaterialDetail(material);
    }

    @Transactional
    public void deleteMaterial(Long materialId) {
        AssignmentMaterial material = getMaterialOrThrow(materialId);
        materialStorageService.delete(material);
        materialMapper.deleteById(materialId);
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail createOrGetSubmission(Long assignmentId, User user) {
        Assignment assignment = getPublishedAssignmentOrThrow(assignmentId);
        AssignmentSubmission submission = findSubmission(assignment.getAssignmentId(), user.getId());
        if (submission == null) {
            LocalDateTime now = LocalDateTime.now();
            submission = AssignmentSubmission.builder()
                    .assignmentId(assignmentId)
                    .studentId(user.getId())
                    .status(SUBMISSION_DRAFT)
                    .createdAt(now)
                    .updatedAt(now)
                    .build();
            submissionMapper.insert(submission);
        }
        return toSubmissionDetail(submission);
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail uploadFile(Long assignmentId, User user, String fileType, MultipartFile file) {
        Assignment assignment = getPublishedAssignmentOrThrow(assignmentId);
        AssignmentSubmission submission = findOrCreateSubmission(assignment.getAssignmentId(), user.getId());
        ensureSubmissionEditable(submission);
        AssignmentSubmissionFile stored = fileStorageService.store(assignmentId, user.getId(), submission.getSubmissionId(), fileType, file);
        fileMapper.insert(stored);
        return toSubmissionDetail(submissionMapper.selectById(submission.getSubmissionId()));
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail saveAnswer(Long assignmentId, User user, AssignmentDtos.AnswerSaveRequest request) {
        Assignment assignment = getPublishedAssignmentOrThrow(assignmentId);
        AssignmentSubmission submission = findOrCreateSubmission(assignment.getAssignmentId(), user.getId());
        ensureSubmissionEditable(submission);
        submission.setAnswerText(request == null ? null : request.getAnswerText());
        submission.setUpdatedAt(LocalDateTime.now());
        submissionMapper.updateById(submission);
        return toSubmissionDetail(submissionMapper.selectById(submission.getSubmissionId()));
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail submit(Long assignmentId, User user, AssignmentDtos.AnswerSaveRequest request) {
        Assignment assignment = getPublishedAssignmentOrThrow(assignmentId);
        AssignmentSubmission submission = findOrCreateSubmission(assignment.getAssignmentId(), user.getId());
        ensureSubmissionEditable(submission);
        if (request != null) {
            submission.setAnswerText(request.getAnswerText());
        }
        boolean hasAnswer = StringUtils.hasText(submission.getAnswerText());
        boolean hasFiles = countFiles(submission.getSubmissionId()) > 0;
        if (!hasAnswer && !hasFiles) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请先填写文字答案或上传材料后再提交考核");
        }
        LocalDateTime now = LocalDateTime.now();
        submission.setStatus(assignment.getDeadline() != null && now.isAfter(assignment.getDeadline())
                ? SUBMISSION_LATE : SUBMISSION_SUBMITTED);
        submission.setSubmittedAt(now);
        submission.setUpdatedAt(now);
        submissionMapper.updateById(submission);
        return toSubmissionDetail(submission);
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail deleteStudentFile(Long fileId, User user) {
        AssignmentSubmissionFile file = fileMapper.selectById(fileId);
        if (file == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "文件不存在");
        }
        AssignmentSubmission submission = getSubmissionOrThrow(file.getSubmissionId());
        if (!submission.getStudentId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权删除该文件");
        }
        ensureSubmissionEditable(submission);
        fileStorageService.delete(file);
        fileMapper.deleteById(fileId);
        return toSubmissionDetail(submissionMapper.selectById(submission.getSubmissionId()));
    }

    public PageResponse<AssignmentDtos.SubmissionSummary> pageSubmissions(Long assignmentId, String status, long page, long pageSize) {
        getAssignmentOrThrow(assignmentId);
        LambdaQueryWrapper<AssignmentSubmission> wrapper = new LambdaQueryWrapper<AssignmentSubmission>()
                .eq(AssignmentSubmission::getAssignmentId, assignmentId)
                .orderByDesc(AssignmentSubmission::getSubmittedAt)
                .orderByDesc(AssignmentSubmission::getUpdatedAt);
        if (StringUtils.hasText(status)) {
            wrapper.eq(AssignmentSubmission::getStatus, status.trim().toUpperCase());
        }
        long total = submissionMapper.selectCount(wrapper);
        Page<AssignmentSubmission> result = submissionMapper.selectPage(new Page<>(page, pageSize), wrapper);
        List<AssignmentDtos.SubmissionSummary> records = result.getRecords().stream()
                .map(this::toSubmissionSummary)
                .collect(Collectors.toList());
        return PageResponse.of(records, total, page, pageSize);
    }

    public long countSubmissionFilesForZip(Long assignmentId, String status) {
        List<AssignmentSubmission> submissions = listSubmissionsForZip(assignmentId, status);
        if (submissions.isEmpty()) {
            return 0;
        }
        return fileMapper.selectCount(new LambdaQueryWrapper<AssignmentSubmissionFile>()
                .in(AssignmentSubmissionFile::getSubmissionId, submissions.stream()
                        .map(AssignmentSubmission::getSubmissionId)
                        .collect(Collectors.toList())));
    }

    public String submissionFilesZipName(Long assignmentId) {
        Assignment assignment = getAssignmentOrThrow(assignmentId);
        return sanitizeZipName(assignment.getTitle()) + "-提交附件.zip";
    }

    public void writeSubmissionFilesZip(Long assignmentId, String status, OutputStream outputStream) throws IOException {
        Assignment assignment = getAssignmentOrThrow(assignmentId);
        List<AssignmentSubmission> submissions = listSubmissionsForZip(assignmentId, status);
        Map<Long, AssignmentSubmission> submissionMap = submissions.stream()
                .collect(Collectors.toMap(AssignmentSubmission::getSubmissionId, item -> item));
        List<Long> submissionIds = submissions.stream()
                .map(AssignmentSubmission::getSubmissionId)
                .collect(Collectors.toList());
        List<AssignmentSubmissionFile> files = submissionIds.isEmpty() ? new ArrayList<>() : fileMapper.selectList(
                new LambdaQueryWrapper<AssignmentSubmissionFile>()
                        .in(AssignmentSubmissionFile::getSubmissionId, submissionIds)
                        .orderByAsc(AssignmentSubmissionFile::getSubmissionId)
                        .orderByAsc(AssignmentSubmissionFile::getCreatedAt)
                        .orderByAsc(AssignmentSubmissionFile::getFileId));
        Set<String> usedEntryNames = new HashSet<>();
        List<String> notes = new ArrayList<>();
        String rootDir = sanitizeZipName(assignment.getTitle());

        try (ZipOutputStream zip = new ZipOutputStream(outputStream)) {
            for (AssignmentSubmissionFile file : files) {
                AssignmentSubmission submission = submissionMap.get(file.getSubmissionId());
                if (submission == null) {
                    continue;
                }
                User student = userMapper.selectById(submission.getStudentId());
                String studentDir = sanitizeZipName(displayName(student) + "_" + submission.getStudentId());
                String fileName = sanitizeZipName(fileTypeText(file.getFileType()) + "_" + file.getOriginalName());
                String entryName = uniqueZipEntryName(rootDir + "/" + studentDir + "/" + fileName, usedEntryNames);
                try (InputStream input = fileStorageService.load(file).getInputStream()) {
                    zip.putNextEntry(new ZipEntry(entryName));
                    byte[] buffer = new byte[8192];
                    int len;
                    while ((len = input.read(buffer)) >= 0) {
                        zip.write(buffer, 0, len);
                    }
                    zip.closeEntry();
                } catch (Exception ex) {
                    notes.add(entryName + "：文件不存在或读取失败");
                }
            }
            if (!notes.isEmpty()) {
                zip.putNextEntry(new ZipEntry(rootDir + "/下载说明.txt"));
                zip.write(String.join("\n", notes).getBytes(StandardCharsets.UTF_8));
                zip.closeEntry();
            }
            zip.finish();
        }
    }

    public AssignmentDtos.SubmissionDetail getAdminSubmission(Long submissionId) {
        return toSubmissionDetail(getSubmissionOrThrow(submissionId));
    }

    public AssignmentDtos.SubmissionDetail getStudentSubmission(Long submissionId, Long userId) {
        AssignmentSubmission submission = getSubmissionOrThrow(submissionId);
        if (!submission.getStudentId().equals(userId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权查看该提交");
        }
        return toSubmissionDetail(submission);
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail grade(Long submissionId, AssignmentDtos.GradeRequest request, User operator) {
        AssignmentSubmission submission = getSubmissionOrThrow(submissionId);
        if (request == null || request.getScore() == null) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请输入评分");
        }
        Assignment assignment = getAssignmentOrThrow(submission.getAssignmentId());
        BigDecimal maxScore = defaultScore(assignment.getTotalScore());
        if (request.getScore().compareTo(BigDecimal.ZERO) < 0 || request.getScore().compareTo(maxScore) > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "评分必须在 0 到满分之间");
        }
        LocalDateTime now = LocalDateTime.now();
        submission.setScore(request.getScore());
        submission.setFeedback(request.getFeedback());
        submission.setStatus(SUBMISSION_GRADED);
        submission.setGradedBy(operator.getId());
        submission.setGradedAt(now);
        submission.setUpdatedAt(now);
        submissionMapper.updateById(submission);
        return toSubmissionDetail(submission);
    }

    @Transactional
    public AssignmentDtos.SubmissionDetail returnSubmission(Long submissionId, AssignmentDtos.GradeRequest request, User operator) {
        AssignmentSubmission submission = getSubmissionOrThrow(submissionId);
        LocalDateTime now = LocalDateTime.now();
        submission.setScore(null);
        submission.setFeedback(request == null ? null : request.getFeedback());
        submission.setStatus(SUBMISSION_RETURNED);
        submission.setGradedBy(operator.getId());
        submission.setGradedAt(now);
        submission.setUpdatedAt(now);
        submissionMapper.updateById(submission);
        return toSubmissionDetail(submission);
    }

    public AssignmentSubmissionFile getFileForDownload(Long fileId, User user, boolean admin) {
        AssignmentSubmissionFile file = fileMapper.selectById(fileId);
        if (file == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "文件不存在");
        }
        AssignmentSubmission submission = getSubmissionOrThrow(file.getSubmissionId());
        if (!admin && !submission.getStudentId().equals(user.getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "无权下载该文件");
        }
        return file;
    }

    public Resource loadFile(AssignmentSubmissionFile file) {
        return fileStorageService.load(file);
    }

    public AssignmentMaterial getMaterialForDownload(Long materialId, User user, boolean admin) {
        AssignmentMaterial material = getMaterialOrThrow(materialId);
        Assignment assignment = getAssignmentOrThrow(material.getAssignmentId());
        if (!admin && !STATUS_PUBLISHED.equalsIgnoreCase(assignment.getStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "材料不存在或考核尚未发布");
        }
        return material;
    }

    public Resource loadMaterial(AssignmentMaterial material) {
        return materialStorageService.load(material);
    }

    private LambdaQueryWrapper<Assignment> assignmentQuery(String keyword, String status, boolean onlyPublished) {
        LambdaQueryWrapper<Assignment> wrapper = new LambdaQueryWrapper<Assignment>()
                .orderByDesc(Assignment::getUpdatedAt);
        if (StringUtils.hasText(keyword)) {
            String like = keyword.trim();
            wrapper.and(q -> q.like(Assignment::getTitle, like).or().like(Assignment::getDescription, like));
        }
        if (onlyPublished) {
            wrapper.eq(Assignment::getStatus, STATUS_PUBLISHED);
        } else if (StringUtils.hasText(status)) {
            wrapper.eq(Assignment::getStatus, STATUS_NO_MATCH.equals(status) ? STATUS_NO_MATCH : status.trim().toUpperCase());
        }
        return wrapper;
    }

    private String restrictStatus(String selectedStatus, String statStatus) {
        if (!StringUtils.hasText(selectedStatus)) {
            return statStatus;
        }
        return statStatus.equalsIgnoreCase(selectedStatus.trim()) ? statStatus : STATUS_NO_MATCH;
    }

    private long countSubmissions(List<Long> assignmentIds, String status) {
        if (assignmentIds == null || assignmentIds.isEmpty()) {
            return 0;
        }
        LambdaQueryWrapper<AssignmentSubmission> wrapper = new LambdaQueryWrapper<AssignmentSubmission>()
                .in(AssignmentSubmission::getAssignmentId, assignmentIds);
        if (StringUtils.hasText(status)) {
            wrapper.eq(AssignmentSubmission::getStatus, status);
        }
        return submissionMapper.selectCount(wrapper);
    }

    private List<AssignmentSubmission> listSubmissionsForZip(Long assignmentId, String status) {
        getAssignmentOrThrow(assignmentId);
        LambdaQueryWrapper<AssignmentSubmission> wrapper = new LambdaQueryWrapper<AssignmentSubmission>()
                .eq(AssignmentSubmission::getAssignmentId, assignmentId);
        if (StringUtils.hasText(status)) {
            wrapper.eq(AssignmentSubmission::getStatus, status.trim().toUpperCase());
        }
        return submissionMapper.selectList(wrapper);
    }

    private AssignmentDtos.AssignmentSummary toAdminSummary(Assignment assignment) {
        AssignmentDtos.AssignmentSummary summary = toSummary(assignment);
        summary.setSubmissionCount(submissionMapper.selectCount(new LambdaQueryWrapper<AssignmentSubmission>()
                .eq(AssignmentSubmission::getAssignmentId, assignment.getAssignmentId())));
        summary.setGradedCount(submissionMapper.selectCount(new LambdaQueryWrapper<AssignmentSubmission>()
                .eq(AssignmentSubmission::getAssignmentId, assignment.getAssignmentId())
                .eq(AssignmentSubmission::getStatus, SUBMISSION_GRADED)));
        return summary;
    }

    private AssignmentDtos.AssignmentSummary toSummary(Assignment assignment) {
        return AssignmentDtos.AssignmentSummary.builder()
                .assignmentId(assignment.getAssignmentId())
                .title(assignment.getTitle())
                .description(assignment.getDescription())
                .category(assignment.getCategory())
                .deadline(assignment.getDeadline())
                .totalScore(assignment.getTotalScore())
                .status(assignment.getStatus())
                .createdBy(assignment.getCreatedBy())
                .createdAt(assignment.getCreatedAt())
                .updatedAt(assignment.getUpdatedAt())
                .build();
    }

    private AssignmentDtos.AssignmentDetail toDetail(Assignment assignment, Long userId) {
        List<AssignmentDtos.QuestionDetail> questions = questionMapper.selectList(new LambdaQueryWrapper<AssignmentQuestion>()
                        .eq(AssignmentQuestion::getAssignmentId, assignment.getAssignmentId())
                        .orderByAsc(AssignmentQuestion::getSortOrder)
                        .orderByAsc(AssignmentQuestion::getQuestionId))
                .stream()
                .map(this::toQuestionDetail)
                .collect(Collectors.toList());
        AssignmentDtos.SubmissionDetail mySubmission = userId == null ? null : toSubmissionDetail(findSubmission(assignment.getAssignmentId(), userId));
        return AssignmentDtos.AssignmentDetail.builder()
                .assignmentId(assignment.getAssignmentId())
                .title(assignment.getTitle())
                .description(assignment.getDescription())
                .category(assignment.getCategory())
                .deadline(assignment.getDeadline())
                .totalScore(assignment.getTotalScore())
                .status(assignment.getStatus())
                .createdAt(assignment.getCreatedAt())
                .updatedAt(assignment.getUpdatedAt())
                .questions(questions)
                .materials(listMaterialDetails(assignment.getAssignmentId()))
                .mySubmission(mySubmission)
                .submissionCount(submissionMapper.selectCount(new LambdaQueryWrapper<AssignmentSubmission>()
                        .eq(AssignmentSubmission::getAssignmentId, assignment.getAssignmentId())))
                .gradedCount(submissionMapper.selectCount(new LambdaQueryWrapper<AssignmentSubmission>()
                        .eq(AssignmentSubmission::getAssignmentId, assignment.getAssignmentId())
                        .eq(AssignmentSubmission::getStatus, SUBMISSION_GRADED)))
                .build();
    }

    private List<AssignmentDtos.MaterialDetail> listMaterialDetails(Long assignmentId) {
        return materialMapper.selectList(new LambdaQueryWrapper<AssignmentMaterial>()
                        .eq(AssignmentMaterial::getAssignmentId, assignmentId)
                        .orderByAsc(AssignmentMaterial::getSortOrder)
                        .orderByAsc(AssignmentMaterial::getMaterialId))
                .stream()
                .map(this::toMaterialDetail)
                .collect(Collectors.toList());
    }

    private AssignmentDtos.QuestionDetail toQuestionDetail(AssignmentQuestion question) {
        return AssignmentDtos.QuestionDetail.builder()
                .questionId(question.getQuestionId())
                .title(question.getTitle())
                .content(question.getContent())
                .score(question.getScore())
                .sortOrder(question.getSortOrder())
                .build();
    }

    private AssignmentDtos.SubmissionSummary toSubmissionSummary(AssignmentSubmission submission) {
        if (submission == null) {
            return null;
        }
        User user = userMapper.selectById(submission.getStudentId());
        return AssignmentDtos.SubmissionSummary.builder()
                .submissionId(submission.getSubmissionId())
                .assignmentId(submission.getAssignmentId())
                .studentId(submission.getStudentId())
                .studentName(displayName(user))
                .status(submission.getStatus())
                .submittedAt(submission.getSubmittedAt())
                .gradedAt(submission.getGradedAt())
                .score(submission.getScore())
                .feedback(submission.getFeedback())
                .fileCount((int) countFiles(submission.getSubmissionId()))
                .build();
    }

    private AssignmentDtos.SubmissionDetail toSubmissionDetail(AssignmentSubmission submission) {
        if (submission == null) {
            return null;
        }
        User user = userMapper.selectById(submission.getStudentId());
        List<AssignmentDtos.SubmissionFileDetail> files = fileMapper.selectList(new LambdaQueryWrapper<AssignmentSubmissionFile>()
                        .eq(AssignmentSubmissionFile::getSubmissionId, submission.getSubmissionId())
                        .orderByDesc(AssignmentSubmissionFile::getCreatedAt))
                .stream()
                .map(this::toFileDetail)
                .collect(Collectors.toList());
        return AssignmentDtos.SubmissionDetail.builder()
                .submissionId(submission.getSubmissionId())
                .assignmentId(submission.getAssignmentId())
                .studentId(submission.getStudentId())
                .studentName(displayName(user))
                .status(submission.getStatus())
                .answerText(submission.getAnswerText())
                .submittedAt(submission.getSubmittedAt())
                .gradedAt(submission.getGradedAt())
                .score(submission.getScore())
                .feedback(submission.getFeedback())
                .files(files)
                .build();
    }

    private AssignmentDtos.SubmissionFileDetail toFileDetail(AssignmentSubmissionFile file) {
        return AssignmentDtos.SubmissionFileDetail.builder()
                .fileId(file.getFileId())
                .submissionId(file.getSubmissionId())
                .fileType(file.getFileType())
                .originalName(file.getOriginalName())
                .mimeType(file.getMimeType())
                .fileSize(file.getFileSize())
                .createdAt(file.getCreatedAt())
                .build();
    }

    private AssignmentDtos.MaterialDetail toMaterialDetail(AssignmentMaterial material) {
        return AssignmentDtos.MaterialDetail.builder()
                .materialId(material.getMaterialId())
                .assignmentId(material.getAssignmentId())
                .materialType(material.getMaterialType())
                .title(material.getTitle())
                .originalName(material.getOriginalName())
                .mimeType(material.getMimeType())
                .fileSize(material.getFileSize())
                .sortOrder(material.getSortOrder())
                .createdAt(material.getCreatedAt())
                .build();
    }

    private void replaceQuestions(Long assignmentId, List<AssignmentDtos.QuestionInput> inputs) {
        questionMapper.delete(new LambdaQueryWrapper<AssignmentQuestion>()
                .eq(AssignmentQuestion::getAssignmentId, assignmentId));
        List<AssignmentDtos.QuestionInput> safeInputs = inputs == null ? new ArrayList<>() : new ArrayList<>(inputs);
        safeInputs.sort(Comparator.comparing(input -> input.getSortOrder() == null ? 0 : input.getSortOrder()));
        int index = 1;
        LocalDateTime now = LocalDateTime.now();
        for (AssignmentDtos.QuestionInput input : safeInputs) {
            if (input == null || !StringUtils.hasText(input.getTitle())) {
                continue;
            }
            questionMapper.insert(AssignmentQuestion.builder()
                    .assignmentId(assignmentId)
                    .title(input.getTitle().trim())
                    .content(input.getContent())
                    .score(input.getScore() == null ? BigDecimal.ZERO : input.getScore())
                    .sortOrder(input.getSortOrder() == null ? index : input.getSortOrder())
                    .createdAt(now)
                    .updatedAt(now)
                    .build());
            index++;
        }
    }

    private Assignment getAssignmentOrThrow(Long assignmentId) {
        Assignment assignment = assignmentMapper.selectById(assignmentId);
        if (assignment == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "考核不存在");
        }
        return assignment;
    }

    private Assignment getPublishedAssignmentOrThrow(Long assignmentId) {
        Assignment assignment = getAssignmentOrThrow(assignmentId);
        if (!STATUS_PUBLISHED.equalsIgnoreCase(assignment.getStatus())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "考核不存在或尚未发布");
        }
        return assignment;
    }

    private AssignmentSubmission getSubmissionOrThrow(Long submissionId) {
        AssignmentSubmission submission = submissionMapper.selectById(submissionId);
        if (submission == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "提交记录不存在");
        }
        return submission;
    }

    private AssignmentMaterial getMaterialOrThrow(Long materialId) {
        AssignmentMaterial material = materialMapper.selectById(materialId);
        if (material == null) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "材料不存在");
        }
        return material;
    }

    private void ensureSubmissionEditable(AssignmentSubmission submission) {
        if (submission == null) {
            return;
        }
        if (SUBMISSION_GRADED.equalsIgnoreCase(submission.getStatus())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "已评分的提交不能再修改");
        }
    }

    private AssignmentSubmission findSubmission(Long assignmentId, Long studentId) {
        return submissionMapper.selectOne(new LambdaQueryWrapper<AssignmentSubmission>()
                .eq(AssignmentSubmission::getAssignmentId, assignmentId)
                .eq(AssignmentSubmission::getStudentId, studentId)
                .last("LIMIT 1"));
    }

    private AssignmentSubmission findOrCreateSubmission(Long assignmentId, Long studentId) {
        AssignmentSubmission submission = findSubmission(assignmentId, studentId);
        if (submission != null) {
            return submission;
        }
        LocalDateTime now = LocalDateTime.now();
        submission = AssignmentSubmission.builder()
                .assignmentId(assignmentId)
                .studentId(studentId)
                .status(SUBMISSION_DRAFT)
                .createdAt(now)
                .updatedAt(now)
                .build();
        submissionMapper.insert(submission);
        return submission;
    }

    private long countFiles(Long submissionId) {
        if (submissionId == null) {
            return 0;
        }
        return fileMapper.selectCount(new LambdaQueryWrapper<AssignmentSubmissionFile>()
                .eq(AssignmentSubmissionFile::getSubmissionId, submissionId));
    }

    private void validateSaveRequest(AssignmentDtos.AssignmentSaveRequest request) {
        if (request == null || !StringUtils.hasText(request.getTitle())) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "请输入考核标题");
        }
    }

    private String normalizeAssignmentStatus(String status) {
        String normalized = StringUtils.hasText(status) ? status.trim().toUpperCase() : "";
        if (!STATUS_DRAFT.equals(normalized) && !STATUS_PUBLISHED.equals(normalized) && !STATUS_ARCHIVED.equals(normalized)) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "考核状态不正确");
        }
        return normalized;
    }

    private BigDecimal defaultScore(BigDecimal score) {
        return score == null ? new BigDecimal("100.00") : score;
    }

    private String displayName(User user) {
        if (user == null) {
            return "未知用户";
        }
        if (StringUtils.hasText(user.getDisplayName())) {
            return user.getDisplayName();
        }
        if (StringUtils.hasText(user.getRealName())) {
            return user.getRealName();
        }
        return user.getUsername();
    }

    private String fileTypeText(String fileType) {
        if ("VIDEO".equalsIgnoreCase(fileType)) {
            return "视频";
        }
        return "文档";
    }

    private String sanitizeZipName(String name) {
        String safe = StringUtils.hasText(name) ? name.trim() : "未命名";
        safe = safe.replaceAll("[\\\\/:*?\"<>|\\r\\n\\t]+", "_");
        safe = safe.replaceAll("\\s+", " ");
        return safe.length() > 120 ? safe.substring(0, 120) : safe;
    }

    private String uniqueZipEntryName(String entryName, Set<String> usedEntryNames) {
        String normalized = entryName.replace('\\', '/');
        if (usedEntryNames.add(normalized)) {
            return normalized;
        }
        int slash = normalized.lastIndexOf('/');
        int dot = normalized.lastIndexOf('.');
        if (dot <= slash) {
            dot = normalized.length();
        }
        String prefix = normalized.substring(0, dot);
        String suffix = normalized.substring(dot);
        int index = 2;
        String candidate;
        do {
            candidate = prefix + "_" + index + suffix;
            index++;
        } while (!usedEntryNames.add(candidate));
        return candidate;
    }
}

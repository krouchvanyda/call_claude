package com.company.erp.features.chats.service;

import com.company.erp.core.database.PageQuery;
import com.company.erp.core.exceptions.BadRequestException;
import com.company.erp.core.exceptions.ForbiddenException;
import com.company.erp.core.exceptions.NotFoundException;
import com.company.erp.features.chats.dto.AddMembersRequest;
import com.company.erp.features.chats.dto.CreateConversationRequest;
import com.company.erp.features.chats.dto.UpdateConversationRequest;
import com.company.erp.features.chats.entity.*;
import com.company.erp.features.chats.repository.ConversationMemberRepository;
import com.company.erp.features.chats.repository.ConversationRepository;
import com.company.erp.features.users.repository.UserRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashSet;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;

@Service
@Transactional
public class ConversationService {

    private final ConversationRepository conversations;
    private final ConversationMemberRepository members;
    private final UserRepository users;

    public ConversationService(ConversationRepository conversations,
                               ConversationMemberRepository members,
                               UserRepository users) {
        this.conversations = conversations;
        this.members = members;
        this.users = users;
    }

    @Transactional(readOnly = true)
    public Page<Conversation> listForUser(Long userId, PageQuery query) {
        return conversations.findAllForUser(userId,
                query.toPageable(Set.of("createdAt"), Sort.by(Sort.Direction.DESC, "createdAt")));
    }

    @Transactional(readOnly = true)
    public Conversation getForUser(Long convId, Long userId) {
        Conversation c = conversations.findWithMembersById(convId)
                .orElseThrow(() -> new NotFoundException("Conversation not found"));
        requireMember(convId, userId);
        return c;
    }

    public Conversation create(Long actorId, CreateConversationRequest req) {
        // Ensure caller is in the member set
        Set<Long> memberIds = new LinkedHashSet<>(req.memberIds());
        memberIds.add(actorId);

        // Validate every user exists
        for (Long uid : memberIds) {
            if (!users.existsById(uid)) {
                throw new NotFoundException("User not found: " + uid);
            }
        }

        if (req.type() == ConversationType.DIRECT) {
            if (memberIds.size() != 2) {
                throw new BadRequestException("DIRECT conversations need exactly 2 members");
            }
            List<Long> two = memberIds.stream().toList();
            var existing = conversations.findDirectBetween(two.get(0), two.get(1));
            if (existing.isPresent()) return existing.get();
        } else if (memberIds.size() < 2) {
            throw new BadRequestException("GROUP conversations need at least 2 members");
        }

        Conversation c = new Conversation();
        c.setType(req.type());
        c.setName(req.type() == ConversationType.GROUP ? req.name() : null);
        c.setAvatarUrl(req.avatarUrl());
        conversations.save(c);

        for (Long uid : memberIds) {
            ConversationMember m = new ConversationMember();
            m.setId(new ConversationMemberId(c.getId(), uid));
            m.setConversation(c);
            m.setRole(uid.equals(actorId) ? MemberRole.ADMIN : MemberRole.MEMBER);
            members.save(m);
        }
        // Reload via the EntityGraph so the caller (controller) can read
        // c.getMembers() after the @Transactional boundary closes.
        return conversations.findWithMembersById(c.getId())
                .orElseThrow(() -> new IllegalStateException("Just-created conversation not found"));
    }

    public Conversation update(Long convId, Long actorId, UpdateConversationRequest req) {
        Conversation c = getForUser(convId, actorId);
        requireAdmin(c, actorId);
        if (req.name()      != null) c.setName(req.name());
        if (req.avatarUrl() != null) c.setAvatarUrl(req.avatarUrl());
        return c;
    }

    public Conversation addMembers(Long convId, Long actorId, AddMembersRequest req) {
        Conversation c = getForUser(convId, actorId);
        requireAdmin(c, actorId);
        if (c.getType() == ConversationType.DIRECT) {
            throw new BadRequestException("Cannot add members to a DIRECT conversation");
        }
        for (Long uid : req.memberIds()) {
            if (members.existsByConversation_IdAndId_UserId(convId, uid)) continue;
            if (!users.existsById(uid)) throw new NotFoundException("User not found: " + uid);
            ConversationMember m = new ConversationMember();
            m.setId(new ConversationMemberId(convId, uid));
            m.setConversation(c);
            m.setRole(MemberRole.MEMBER);
            ConversationMember saved = members.save(m);
            c.getMembers().add(saved);
        }
        return c;
    }

    public Conversation removeMember(Long convId, Long actorId, Long targetUserId) {
        Conversation c = getForUser(convId, actorId);
        // A user can remove themselves; otherwise admin only.
        if (!actorId.equals(targetUserId)) {
            requireAdmin(c, actorId);
        }
        if (c.getType() == ConversationType.DIRECT) {
            throw new BadRequestException("Cannot remove members from a DIRECT conversation");
        }
        ConversationMember m = members.findByConversation_IdAndId_UserId(convId, targetUserId)
                .orElseThrow(() -> new NotFoundException("Member not in conversation"));
        members.delete(m);
        c.getMembers().removeIf(x -> x.getUserId().equals(targetUserId));
        return c;
    }

    /**
     * Hard-delete a conversation (and, via DB-level ON DELETE CASCADE, all of
     * its messages, members, reactions, calls, and call participants).
     *
     * <ul>
     *   <li>GROUP: only the conversation admin may delete.</li>
     *   <li>DIRECT: either participant may delete.</li>
     * </ul>
     *
     * Returns the set of user ids that were members of the conversation at
     * deletion time, so the controller can fan a {@code conversation.remove}
     * envelope to each of them.
     */
    public Set<Long> delete(Long convId, Long actorId) {
        Conversation c = getForUser(convId, actorId);
        if (c.getType() == ConversationType.GROUP) {
            requireAdmin(c, actorId);
        }
        // Snapshot member ids BEFORE the cascade wipes the join table.
        Set<Long> formerMembers = new HashSet<>(conversations.findMemberUserIds(convId));
        conversations.delete(c);
        return formerMembers;
    }

    public ConversationMember markRead(Long convId, Long userId, Long lastReadMessageId) {
        ConversationMember m = requireMember(convId, userId);
        m.setLastReadMessageId(lastReadMessageId);
        return m;
    }

    public ConversationMember requireMember(Long convId, Long userId) {
        return members.findByConversation_IdAndId_UserId(convId, userId)
                .orElseThrow(() -> new ForbiddenException("Not a member of this conversation"));
    }

    public Set<Long> memberUserIds(Long convId) {
        return new HashSet<>(conversations.findMemberUserIds(convId));
    }

    private void requireAdmin(Conversation c, Long userId) {
        ConversationMember m = members.findByConversation_IdAndId_UserId(c.getId(), userId)
                .orElseThrow(() -> new ForbiddenException("Not a member of this conversation"));
        if (m.getRole() != MemberRole.ADMIN) {
            throw new ForbiddenException("Admin role required");
        }
    }
}

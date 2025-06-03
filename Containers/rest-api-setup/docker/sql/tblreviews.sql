-- Table structure for table `tblreviews`
CREATE TABLE IF NOT EXISTS `tblreviews` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `BookId` int(11) NOT NULL,
  `StudentId` varchar(100) NOT NULL,
  `Rating` int(1) NOT NULL CHECK (Rating >= 1 AND Rating <= 5),
  `ReviewText` text NOT NULL,
  `ReviewDate` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `Status` int(1) NOT NULL DEFAULT 1 COMMENT '0=Pending, 1=Approved',
  PRIMARY KEY (`id`),
  KEY `BookId` (`BookId`),
  KEY `StudentId` (`StudentId`),
  UNIQUE KEY `unique_review` (`BookId`, `StudentId`) -- Ensures one review per student per book
) ENGINE=InnoDB DEFAULT CHARSET=latin1;

-- Add foreign key constraints (if tables already exist)
ALTER TABLE `tblreviews`
  ADD CONSTRAINT `fk_review_book` FOREIGN KEY (`BookId`) REFERENCES `tblbooks` (`id`) ON DELETE CASCADE,
  ADD CONSTRAINT `fk_review_student` FOREIGN KEY (`StudentId`) REFERENCES `tblstudents` (`StudentId`) ON DELETE CASCADE;

-- Create index for better performance
CREATE INDEX idx_review_date ON tblreviews(ReviewDate);
CREATE INDEX idx_review_status ON tblreviews(Status);